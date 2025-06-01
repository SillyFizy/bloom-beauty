#!/bin/bash

BASE_URL="http://localhost:8001"
API_V1="${BASE_URL}/api/v1"

echo "===== Testing API Endpoints ====="

# Test products endpoints
echo "\n--- Testing Products API ---"
echo "GET ${API_V1}/products/"
curl -s "${API_V1}/products/" | python3 -m json.tool | head -20

echo "\n--- Testing Categories ---"
echo "GET ${API_V1}/products/categories/"
curl -s "${API_V1}/products/categories/" | python3 -m json.tool

echo "\n--- Testing Featured Products ---"
echo "GET ${API_V1}/products/featured/"
curl -s "${API_V1}/products/featured/" | python3 -m json.tool

# Test users endpoints (public ones)
echo "\n--- Testing Users API ---"
echo "GET ${API_V1}/users/"
curl -s "${API_V1}/users/" | python3 -m json.tool

# Test cart endpoints
echo "\n--- Testing Cart API ---"
echo "GET ${API_V1}/cart/"
curl -s "${API_V1}/cart/" | python3 -m json.tool

echo "\n===== API Testing Complete =====" 