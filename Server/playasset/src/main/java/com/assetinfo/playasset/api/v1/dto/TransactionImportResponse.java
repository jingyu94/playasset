package com.assetinfo.playasset.api.v1.dto;

import java.util.List;

public record TransactionImportResponse(
        int totalRows,
        int importedRows,
        int failedRows,
        List<String> errors) {
}
