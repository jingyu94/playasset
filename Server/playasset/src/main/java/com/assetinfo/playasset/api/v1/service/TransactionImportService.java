package com.assetinfo.playasset.api.v1.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.assetinfo.playasset.api.v1.dto.CreateTransactionRequest;
import com.assetinfo.playasset.api.v1.dto.TransactionImportResponse;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository;

@Service
public class TransactionImportService {

    private final PlatformQueryRepository repository;
    private final PlatformCacheEvictService cacheEvictService;

    public TransactionImportService(
            PlatformQueryRepository repository,
            PlatformCacheEvictService cacheEvictService) {
        this.repository = repository;
        this.cacheEvictService = cacheEvictService;
    }

    @Transactional
    public TransactionImportResponse importTransactionsFromExcel(long userId, long accountId, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Empty file");
        }
        if (!repository.isAccountOwnedByUser(userId, accountId)) {
            throw new IllegalArgumentException("Account ownership validation failed");
        }

        DataFormatter formatter = new DataFormatter();
        int totalRows = 0;
        int importedRows = 0;
        List<String> errors = new ArrayList<>();
        Map<String, Long> assetIdCache = new HashMap<>();

        try (Workbook workbook = WorkbookFactory.create(file.getInputStream())) {
            Sheet sheet = workbook.getNumberOfSheets() > 0 ? workbook.getSheetAt(0) : null;
            if (sheet == null || sheet.getPhysicalNumberOfRows() <= 1) {
                return new TransactionImportResponse(0, 0, 0, List.of("No rows to import"));
            }

            Row header = sheet.getRow(0);
            Map<String, Integer> indexes = buildHeaderIndexes(header, formatter);

            for (int rowIndex = 1; rowIndex <= sheet.getLastRowNum(); rowIndex++) {
                Row row = sheet.getRow(rowIndex);
                if (row == null || isRowBlank(row, formatter)) {
                    continue;
                }
                totalRows++;

                try {
                    String symbol = readRequiredCell(row, indexes, Set.of("symbol"), formatter).toUpperCase(Locale.ROOT);
                    String side = normalizeTradeSide(readRequiredCell(row, indexes, Set.of("side"), formatter));
                    BigDecimal quantity = readRequiredDecimal(row, indexes, Set.of("quantity", "qty"), formatter);
                    BigDecimal price = readRequiredDecimal(row, indexes, Set.of("price"), formatter);
                    BigDecimal fee = readOptionalDecimal(row, indexes, Set.of("fee"), formatter);
                    BigDecimal tax = readOptionalDecimal(row, indexes, Set.of("tax"), formatter);
                    String occurredAt = readOptionalDateTime(
                            row,
                            indexes,
                            Set.of("occurredat", "occurred_at", "date", "datetime"),
                            formatter);

                    Long assetId = assetIdCache.computeIfAbsent(symbol, repository::findAssetIdBySymbol);
                    if (assetId == null) {
                        throw new IllegalArgumentException("Unknown symbol: " + symbol);
                    }

                    repository.createTransaction(new CreateTransactionRequest(
                            accountId,
                            assetId,
                            side,
                            quantity,
                            price,
                            fee,
                            tax,
                            occurredAt));
                    importedRows++;
                } catch (Exception ex) {
                    errors.add("row " + (rowIndex + 1) + ": " + ex.getMessage());
                }
            }
        } catch (Exception ex) {
            throw new IllegalArgumentException("Failed to parse Excel file: " + ex.getMessage(), ex);
        }

        cacheEvictService.evictMarketDrivenCaches();
        return new TransactionImportResponse(
                totalRows,
                importedRows,
                Math.max(0, totalRows - importedRows),
                errors.stream().limit(30).toList());
    }

    private Map<String, Integer> buildHeaderIndexes(Row header, DataFormatter formatter) {
        if (header == null) {
            throw new IllegalArgumentException("Header row is missing");
        }
        Map<String, Integer> indexes = new HashMap<>();
        for (Cell cell : header) {
            String key = normalizeHeaderKey(formatter.formatCellValue(cell));
            if (!key.isEmpty()) {
                indexes.putIfAbsent(key, cell.getColumnIndex());
            }
        }
        if (!indexes.containsKey("symbol") || !indexes.containsKey("side")
                || !indexes.containsKey("quantity") || !indexes.containsKey("price")) {
            throw new IllegalArgumentException("Required headers: symbol, side, quantity, price");
        }
        return indexes;
    }

    private String normalizeHeaderKey(String header) {
        if (header == null) {
            return "";
        }
        String normalized = header.trim().toLowerCase(Locale.ROOT)
                .replace(" ", "")
                .replace("_", "")
                .replace("-", "");
        return switch (normalized) {
            case "종목", "티커", "심볼" -> "symbol";
            case "구분", "매수매도", "매매구분" -> "side";
            case "수량", "주수" -> "quantity";
            case "단가", "가격", "체결가" -> "price";
            case "수수료" -> "fee";
            case "세금", "tax" -> "tax";
            case "일자", "날짜", "체결일", "체결시간" -> "occurredat";
            default -> normalized;
        };
    }

    private String readRequiredCell(Row row, Map<String, Integer> indexes, Set<String> keys, DataFormatter formatter) {
        String value = readCell(row, indexes, keys, formatter);
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Missing required field: " + keys.iterator().next());
        }
        return value.trim();
    }

    private BigDecimal readRequiredDecimal(Row row, Map<String, Integer> indexes, Set<String> keys, DataFormatter formatter) {
        String raw = readRequiredCell(row, indexes, keys, formatter);
        try {
            return new BigDecimal(raw.replace(",", "")).setScale(6, RoundingMode.HALF_UP);
        } catch (Exception ex) {
            throw new IllegalArgumentException("Invalid number in " + keys.iterator().next() + ": " + raw);
        }
    }

    private BigDecimal readOptionalDecimal(Row row, Map<String, Integer> indexes, Set<String> keys, DataFormatter formatter) {
        String raw = readCell(row, indexes, keys, formatter);
        if (raw == null || raw.isBlank()) {
            return BigDecimal.ZERO.setScale(6, RoundingMode.HALF_UP);
        }
        try {
            return new BigDecimal(raw.replace(",", "")).setScale(6, RoundingMode.HALF_UP);
        } catch (Exception ex) {
            throw new IllegalArgumentException("Invalid number in " + keys.iterator().next() + ": " + raw);
        }
    }

    private String readOptionalDateTime(Row row, Map<String, Integer> indexes, Set<String> keys, DataFormatter formatter) {
        Integer index = resolveColumnIndex(indexes, keys);
        if (index == null) {
            return null;
        }
        Cell cell = row.getCell(index);
        if (cell == null) {
            return null;
        }
        if (DateUtil.isCellDateFormatted(cell)) {
            Instant instant = cell.getDateCellValue().toInstant();
            return LocalDateTime.ofInstant(instant, ZoneId.systemDefault()).withNano(0).toString();
        }
        String raw = formatter.formatCellValue(cell).trim();
        if (raw.isEmpty()) {
            return null;
        }
        try {
            return LocalDateTime.parse(raw).withNano(0).toString();
        } catch (Exception ignored) {
            try {
                return LocalDate.parse(raw).atStartOfDay().toString();
            } catch (Exception ex) {
                throw new IllegalArgumentException("Invalid date/datetime: " + raw);
            }
        }
    }

    private String normalizeTradeSide(String sideRaw) {
        String v = sideRaw.trim().toUpperCase(Locale.ROOT);
        return switch (v) {
            case "BUY", "B", "매수" -> "BUY";
            case "SELL", "S", "매도" -> "SELL";
            default -> throw new IllegalArgumentException("Invalid side: " + sideRaw);
        };
    }

    private String readCell(Row row, Map<String, Integer> indexes, Set<String> keys, DataFormatter formatter) {
        Integer index = resolveColumnIndex(indexes, keys);
        if (index == null) {
            return null;
        }
        Cell cell = row.getCell(index);
        if (cell == null) {
            return null;
        }
        return formatter.formatCellValue(cell);
    }

    private Integer resolveColumnIndex(Map<String, Integer> indexes, Set<String> keys) {
        for (String key : keys) {
            Integer found = indexes.get(key);
            if (found != null) {
                return found;
            }
        }
        return null;
    }

    private boolean isRowBlank(Row row, DataFormatter formatter) {
        for (Cell cell : row) {
            if (!formatter.formatCellValue(cell).trim().isEmpty()) {
                return false;
            }
        }
        return true;
    }
}
