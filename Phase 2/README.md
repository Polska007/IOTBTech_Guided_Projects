Phase 2: Containerize ZeetaFin and Push Images to Amazon ECR
1. Overview
Phase 2 containerizes the ZeetaFin ERP frontend and backend, runs the complete application locally with PostgreSQL, and publishes the tested application images to Amazon Elastic Container Registry (ECR).
The implementation uses plain Docker commands rather than Docker Compose.
2. Objectives
Understand the frontend and backend application requirements.
Create production-ready Docker images for the NestJS backend and Next.js frontend.
Run PostgreSQL with persistent storage.
connect the frontend, backend, and database through a dedicated Docker network.
Validate the backend through Swagger.
Seed the database and test the application login flow.
Push versioned frontend and backend images to private Amazon ECR repositories.
Record implementation evidence, warnings, errors, causes, and fixes.
3. Architecture
```text
Windows browser
    |
    |-- http://localhost:3000
    v
zeetafin-fe (Next.js, port 3000)
    |
    |-- http://localhost:3001/api
    v
zeetafin-be (NestJS, port 3001)
    |
    |-- Docker network: zeetafin-net
    v
zeetafin-db (PostgreSQL, port 5432 internal only)
    |
    v
zeetafin-pgdata (named Docker volume)
```
The local application images are tagged as:
```text
zeetafin-fe:1.0
zeetafin-be:1.0
```
The PostgreSQL runtime uses:
```text
postgres:16-alpine
```
4. Repository Layout
```text
Phase 2/
|-- README.md
|-- evidence/
|   |-- 01-backend-build/
|   |-- 02-frontend-build/
|   |-- 03-local-runtime/
|   |-- 04-swagger/
|   |-- 05-login/
|   |-- 06-ecr-backend/
|   `-- 07-ecr-frontend/
|-- ZeetaFin-BE/
|   |-- Dockerfile
|   |-- .dockerignore
|   |-- package.json
|   |-- package-lock.json
|   `-- src/
`-- ZeetaFin-FE/
    |-- Dockerfile
    |-- .dockerignore
    |-- package.json
    |-- package-lock.json
    |-- next.config.js
    |-- app/
    |-- components/
    `-- lib/
```
5. Prerequisites
Docker Desktop running on Windows.
Git Bash or PowerShell.
AWS CLI v2 configured for an IAM identity.
Access to private Amazon ECR repositories.
AWS region: `eu-west-1`.
The repository must not contain passwords, JWT secrets, AWS keys, `.env` files, or Terraform state.
6. Backend Containerization
6.1 Backend characteristics
The backend is a NestJS and TypeScript application. It:
builds with `npm run build`;
starts in production with `node dist/main`;
listens on port `3001`;
connects to PostgreSQL;
exposes Swagger at `/api/docs`;
uses environment variables for database and JWT configuration.
6.2 Backend Dockerfile design
The backend Dockerfile uses three stages:
builder: installs all dependencies and compiles TypeScript into `dist/`;
production-deps: installs production dependencies only;
runner: copies the compiled output and production dependencies into the final image.
The final container runs as the non-root `node` user.
6.3 Backend build
From `Phase 2/ZeetaFin-BE`:
```bash
docker build -t zeetafin-be:1.0 .
```
Verification:
```bash
docker image ls zeetafin-be
```
The build succeeded and produced `zeetafin-be:1.0`.
7. Docker Network and PostgreSQL
7.1 Create the network
```bash
docker network create zeetafin-net
docker network ls --filter name=zeetafin-net
```
7.2 Create persistent storage
```bash
docker volume create zeetafin-pgdata
docker volume ls --filter name=zeetafin-pgdata
```
7.3 Run PostgreSQL
The database password was entered into a temporary shell variable and was not committed to the repository.
```bash
docker run -d \
  --name zeetafin-db \
  --network zeetafin-net \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD="$DB_PASSWORD" \
  -e POSTGRES_DB=zeetafin \
  -v zeetafin-pgdata:/var/lib/postgresql/data \
  postgres:16-alpine
```
Port `5432` was not published to the Windows host. The backend reaches PostgreSQL through `zeetafin-net` using the container name `zeetafin-db`.
Readiness check:
```bash
docker exec zeetafin-db pg_isready -U postgres -d zeetafin
```
Observed result:
```text
/var/run/postgresql:5432 - accepting connections
```
8. Run and Test the Backend
The backend container was started with database and JWT settings supplied at runtime rather than baked into the image.
```bash
docker run -d \
  --name zeetafin-be \
  --network zeetafin-net \
  -p 3001:3001 \
  -e PORT=3001 \
  -e DB_HOST=zeetafin-db \
  -e DB_PORT=5432 \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e DB_NAME=zeetafin \
  -e JWT_SECRET="$JWT_SECRET" \
  -e NODE_ENV=production \
  -e DB_SYNC=true \
  -e DB_LOGGING=false \
  zeetafin-be:1.0
```
A bounded log check showed:
```text
Nest application successfully started
ZeetaFin API running on http://localhost:3001
```
Swagger verification:
```bash
curl -I http://localhost:3001/api/docs
```
Observed result:
```text
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
```
9. Database Seeding
The production backend image does not include TypeScript source or development tooling. A temporary image was therefore created from the Dockerfile's `builder` stage:
```bash
docker build --target builder -t zeetafin-be-seed:1.0 .
```
The seed was executed in a temporary container attached to `zeetafin-net`:
```bash
docker run --rm \
  --network zeetafin-net \
  -e DB_HOST=zeetafin-db \
  -e DB_PORT=5432 \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e DB_NAME=zeetafin \
  -e JWT_SECRET="$JWT_SECRET" \
  -e NODE_ENV=production \
  -e DB_SYNC=true \
  zeetafin-be-seed:1.0 \
  npm run seed
```
Observed result:
```text
Database connected & synced
Admin user created
Setup complete
```
The seed output exposed a known default test credential. That credential is intentionally not reproduced in this public README and must be changed for any non-lab deployment.
10. Frontend Containerization
10.1 Frontend characteristics
The frontend is a Next.js application configured with `output: 'standalone'`. It listens on port `3000`, and the browser calls the backend API through `NEXT_PUBLIC_API_URL` or the local fallback API address.
10.2 Frontend Dockerfile design
The frontend Dockerfile uses three stages:
deps: installs dependencies with `npm ci`;
builder: builds the standalone Next.js output;
runner: copies `.next/standalone` and `.next/static` into a non-root production image.
The runtime container includes a health check and runs as the `nextjs` user.
10.3 Frontend build
From `Phase 2/ZeetaFin-FE`:
```bash
docker build -t zeetafin-fe:1.0 .
```
After correcting the `public` directory issue recorded in the error log, the build succeeded and produced `zeetafin-fe:1.0`.
11. Run and Test the Frontend
```bash
docker run -d \
  --name zeetafin-fe \
  --network zeetafin-net \
  -p 3000:3000 \
  zeetafin-fe:1.0
```
Runtime verification showed:
```text
zeetafin-fe: Up (healthy)
zeetafin-be: Up
zeetafin-db: Up
```
The application was opened at `http://localhost:3000`, and the seeded test account successfully reached the application after login. This validated the complete local flow:
```text
Browser -> frontend container -> backend container -> PostgreSQL container
```
12. Amazon ECR
Two private repositories were created in `eu-west-1`:
```text
zeetafin-be
zeetafin-fe
```
Docker authenticated successfully to the private ECR registry after the required IAM permission was added.
12.1 Backend image
The tested local backend image was tagged and pushed as:
```text
zeetafin-be:1.0
```
ECR verification returned image tag `1.0` for the `zeetafin-be` repository.
12.2 Frontend image
The tested local frontend image was tagged and pushed as:
```text
zeetafin-fe:1.0
```
ECR verification returned image tag `1.0` for the `zeetafin-fe` repository.
The AWS account-specific registry URI is intentionally omitted from this public README.
13. Evidence Checklist
Save screenshots in the matching folders under `Phase 2/evidence/`. Redact AWS account IDs, ARNs, local Windows user paths, public IP addresses, and any secrets before committing.
[ ] `01-backend-build/`: successful `zeetafin-be:1.0` build or image list.
[ ] `02-frontend-build/`: successful `zeetafin-fe:1.0` build or image list.
[ ] `03-local-runtime/`: `docker ps` showing FE healthy, BE running, and PostgreSQL running.
[ ] `04-swagger/`: Swagger UI and/or terminal output showing HTTP 200.
[ ] `05-login/`: successful ZeetaFin login/dashboard without exposed credentials.
[ ] `06-ecr-backend/`: backend repository showing image tag `1.0`.
[ ] `07-ecr-frontend/`: frontend repository showing image tag `1.0`.
Recommended filenames:
```text
01-backend-build/backend-image.png
02-frontend-build/frontend-image.png
03-local-runtime/docker-containers.png
04-swagger/swagger-http-200.png
04-swagger/swagger-ui.png
05-login/login-page.png
05-login/dashboard.png
06-ecr-backend/ecr-backend-1.0.png
07-ecr-frontend/ecr-frontend-1.0.png
```
14. Error and Warning Log
Stage	What happened	Cause	Fix	Result
Early Docker build	`docker build -t zeetafinapp` failed	The required Docker build context `.` was omitted	Re-ran the build with the current directory as the context	Build proceeded
Earlier frontend build	`node.exe: not found`	Windows `node_modules` was copied into a Linux image because `.dockerignore` was incomplete	Added a correct `.dockerignore` and rebuilt without the Windows modules	Linux build proceeded
Frontend image packaging	`/app/public` was not found	The Dockerfile tried to copy a `public` directory that the frontend did not contain	Removed the unnecessary `public` COPY instruction	Frontend image built successfully
Backend seed	`pg` emitted a deprecation warning while seeding	The seed implementation called `client.query()` while another query was executing	Recorded as a non-blocking application warning; no deployment workaround was required	Database connected, synchronized, and seeded successfully
AWS CLI	`Unknown output type: .json`	AWS CLI output was configured as `.json` rather than `json`	Corrected the AWS CLI output setting to `json`	AWS CLI commands worked
ECR login	`AccessDeniedException` for `ecr:GetAuthorizationToken`	The IAM identity did not have the required private ECR authorization permission	Added an appropriate private ECR push policy to the IAM group	Docker login succeeded
ECR login region	Login was first attempted in `us-east-1`	The command targeted a different region from the project repositories	Used `eu-west-1`	Authentication targeted the correct registry
Backend ECR tag	`No such image: zeetafin-be:latest`	The tested local backend image was tagged `1.0`, not `latest`	Tagged and pushed `zeetafin-be:1.0`	Backend image reached ECR
Backend rebuild attempt	Dockerfile was not found	The build was attempted from the repository root rather than the backend directory	Reused the already-tested local `zeetafin-be:1.0` image	No rebuild was required
15. Security Controls Applied
`.env` files and secrets were not copied into Docker images.
Database and JWT secrets were supplied at container runtime.
PostgreSQL port `5432` was not published to the host.
Frontend and backend production containers run as non-root users.
Multi-stage builds reduce the contents of runtime images.
Dependency installation uses lock files and `npm ci`.
Private ECR is used for application images.
ECR access is provided through IAM permissions.
Account-specific identifiers must be redacted from screenshots and public documentation.
The default seeded credential must be changed for any environment beyond this lab.
16. Useful Verification Commands
```bash
docker image ls zeetafin-be
docker image ls zeetafin-fe
docker ps
docker network ls --filter name=zeetafin-net
docker volume ls --filter name=zeetafin-pgdata
docker exec zeetafin-db pg_isready -U postgres -d zeetafin
curl -I http://localhost:3001/api/docs
```
ECR verification:
```powershell
aws ecr describe-images --repository-name zeetafin-be --region eu-west-1 --query "imageDetails[].imageTags"
aws ecr describe-images --repository-name zeetafin-fe --region eu-west-1 --query "imageDetails[].imageTags"
```
17. Phase 2 Result
Phase 2 achieved the required flow:
```text
ZeetaFin source code
    -> Docker frontend and backend images
    -> local PostgreSQL-backed application
    -> successful Swagger and login validation
    -> private Amazon ECR repositories
```
Both application images are available in ECR with the version tag `1.0`.
18. Open Items Before Phase 3
Add and redact all evidence screenshots.
Run the repository security checks before staging and committing.
Confirm `.env`, Terraform state, keys, build folders, and `node_modules` are ignored.
Decide how GitHub Actions will reach the managed EC2 instance.
Decide how the EC2 instance will authenticate to ECR.
Decide whether deployment will use an nginx reverse proxy on port `80`.
Decide how PostgreSQL will run in the deployed environment.
Decide how the frontend API URL will remain stable if the server public IP changes.
