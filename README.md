# B4-1 — Linux 시스템 관제 자동화

Linux 서버 운영 환경을 구성하고 Bash 기반 `monitor.sh`를 구현하여 애플리케이션 상태와 시스템 리소스를 자동으로 관제하는 미션입니다.

보너스 과제는 제외하고 필수 요구사항만 구현했습니다.

## 구현 내용

- SSH 포트 `20022` 변경
- Root 원격 로그인 차단
- UFW 활성화
  - `20022/tcp`
  - `15034/tcp`
- 역할 기반 사용자/그룹 구성
  - `agent-admin`
  - `agent-dev`
  - `agent-test`
  - `agent-common`
  - `agent-core`
- ACL 기반 공유/보안 디렉터리 권한 분리
- 애플리케이션 실행 환경 구성
- Boot Sequence 5단계 `[OK]`
- `Agent READY`
- `0.0.0.0:15034` LISTEN
- Bash 기반 시스템 관제 스크립트 구현
- CPU / MEM / DISK 사용률 수집
- 임계값 초과 시 `[WARNING]`
- `/var/log/agent-app/monitor.log` 누적 기록
- logrotate `10MB / 10개` 정책
- `agent-admin` crontab 매분 실행

## 개발 환경

| 항목 | 값 |
|---|---|
| Host | Intel macOS |
| Linux | OrbStack Linux Machine |
| OS | Ubuntu 22.04.5 LTS |
| Architecture | x86_64 |
| Application | `agent-app-linux-x86` |
| Script | Bash |

## Repository 구조

```text
B4-1/
├── bin/
│   └── monitor.sh
├── docs/
│   ├── 요구사항_수행_내역서.md
│   └── 필수_증거_체크리스트.md
├── images/
│   ├── ssh/
│   ├── firewall/
│   ├── permissions/
│   ├── application/
│   ├── monitor/
│   └── automation/
├── .gitignore
└── README.md
```

`provided/` 디렉터리의 제공 애플리케이션 압축 파일은 Git에서 제외합니다.

## `monitor.sh`

소스:

```text
bin/monitor.sh
```

실제 운영 경로:

```text
/home/agent-admin/agent-app/bin/monitor.sh
```

운영 권한:

```text
owner: agent-dev
group: agent-core
mode: 750
```

주요 기능:

1. 애플리케이션 프로세스 Health Check
2. TCP `15034` LISTEN 확인
3. UFW 상태 확인
4. CPU 사용률 수집
5. MEM 사용률 수집
6. Root 파티션 디스크 사용률 수집
7. 임계값 경고
8. `monitor.log` 기록

임계값:

```text
CPU > 20%
MEM > 10%
DISK_USED > 80%
```

로그 포맷:

```text
[YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%
```

## 실행 환경

```text
AGENT_HOME=/home/agent-admin/agent-app
AGENT_PORT=15034
AGENT_UPLOAD_DIR=/home/agent-admin/agent-app/upload_files
AGENT_KEY_PATH=/home/agent-admin/agent-app/api_keys
AGENT_LOG_DIR=/var/log/agent-app
```

> 과제 문서의 키 경로 표기와 실제 제공 바이너리의 Boot Sequence 검증 조건에 차이가 있었습니다. 실제 바이너리는 `AGENT_KEY_PATH`에 `api_keys` 디렉터리를 요구하고 해당 디렉터리의 `secret.key`를 검사하므로, 실제 실행 검증 조건에 맞춰 구성했습니다. 상세 내용은 수행 내역서를 참고하십시오.

## 문서

- [요구사항 수행 내역서](docs/요구사항_수행_내역서.md)
- [필수 증거 자료 체크리스트](docs/필수_증거_체크리스트.md)

## 증거 자료

주요 증거 자료는 `images/` 아래에 단계별로 정리했습니다.

```text
images/
├── ssh/
├── firewall/
├── permissions/
├── application/
├── monitor/
└── automation/
```

## 제출 전 확인 사항

현재 GitHub 저장소 점검 기준으로 `images/automation/04_cron_auto_execution.png`가 확인되지 않습니다.

최종 제출 전 **cron 등록 후 1분이 지나 `monitor.log`의 라인 수와 새로운 타임스탬프가 증가한 화면**을 해당 경로에 추가하고, `docs/필수_증거_체크리스트.md`의 미완료 항목을 `[x]`로 변경해야 합니다.
