@echo off
setlocal

echo === Face Recognition API Authentication Examples ===

set BASE_URL=http://127.0.0.1:8000

echo.
echo 1. Register a new user:
curl -X POST "%BASE_URL%/api/register" ^
  -H "Content-Type: application/json" ^
  -d "{^
    \"name\": \"John Doe\",^
    \"email\": \"john@example.com\",^
    \"password\": \"password123\",^
    \"password_confirmation\": \"password123\"^
  }"

echo.
echo.
echo 2. Login:
curl -X POST "%BASE_URL%/api/login" ^
  -H "Content-Type: application/json" ^
  -d "{^
    \"email\": \"john@example.com\",^
    \"password\": \"password123\"^
  }"

echo.
echo.
echo 3. To access protected routes, use the token from login response:
echo Example:
echo curl -X GET %BASE_URL%/api/user ^
echo   -H "Authorization: Bearer YOUR_TOKEN_HERE"

echo.
echo 4. Logout:
echo curl -X POST %BASE_URL%/api/logout ^
echo   -H "Authorization: Bearer YOUR_TOKEN_HERE"

echo.
echo === End of Examples ===
pause