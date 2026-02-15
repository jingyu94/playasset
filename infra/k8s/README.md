# PlayAsset Kubernetes Base

## 적용
```bash
kubectl apply -k infra/k8s/base
```

## 포함 컴포넌트
- playasset-mysql (StatefulSet)
- playasset-redis (Deployment)
- playasset-kafka (Deployment, KRaft)
- playasset-kafka-ui (Deployment)
- playasset-server (Deployment)
- playasset-web (Deployment)
- playasset-portfolio-service (미래 마이크로서비스 placeholder, replicas=0)
- playasset-public Ingress (AWS ALB annotation 포함)

## 배포 전 반드시 변경
- `ghcr.io/REPLACE_ORG/...` 이미지 경로
- `ingress.yaml`의 도메인/ACM 인증서 ARN
- `app-secret.yaml`, `mysql.yaml` 비밀번호
- CORS 허용 도메인
