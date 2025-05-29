#!/usr/bin/env python3
"""
API Testing Script for Joulina Backend
"""
import requests
import json
import sys

BASE_URL = "http://localhost:8001"
API_V1 = f"{BASE_URL}/api/v1"
TOKEN = None  # Will store auth token after login

def print_response(response, limit=10):
    """Print API response in a readable format with line limit option"""
    try:
        data = response.json()
        formatted = json.dumps(data, indent=2)
        if limit:
            lines = formatted.split('\n')
            if len(lines) > limit:
                print('\n'.join(lines[:limit]))
                print(f"... [truncated {len(lines) - limit} lines]")
            else:
                print(formatted)
        else:
            print(formatted)
    except:
        print(response.text)
    print(f"Status: {response.status_code}")
    print("-" * 50)

def test_endpoint(url, method="GET", data=None, auth=False, description=None):
    """Test an API endpoint and print the response"""
    headers = {}
    if auth and TOKEN:
        headers["Authorization"] = f"Bearer {TOKEN}"
    
    if description:
        print(f"\n=== {description} ===")
    print(f"{method} {url}")
    
    if method == "GET":
        response = requests.get(url, headers=headers)
    elif method == "POST":
        response = requests.post(url, json=data, headers=headers)
    elif method == "PUT":
        response = requests.put(url, json=data, headers=headers)
    elif method == "DELETE":
        response = requests.delete(url, headers=headers)
        
    print_response(response)
    return response

def login(username, password):
    """Login and get JWT token"""
    global TOKEN
    print("\n=== Logging in ===")
    url = f"{API_V1}/users/token/"
    data = {"username": username, "password": password}
    response = requests.post(url, json=data)
    
    if response.status_code == 200:
        token_data = response.json()
        TOKEN = token_data.get("access")
        print(f"Login successful. Token acquired.")
    else:
        print("Login failed.")
        print_response(response)

def test_product_endpoints():
    """Test various product-related endpoints"""
    test_endpoint(f"{API_V1}/products/", description="All Products")
    test_endpoint(f"{API_V1}/products/featured/", description="Featured Products")
    test_endpoint(f"{API_V1}/products/on_sale/", description="Products On Sale")
    test_endpoint(f"{API_V1}/products/categories/", description="Product Categories")
    test_endpoint(f"{API_V1}/products/brands/", description="Product Brands")

def test_user_endpoints(auth=False):
    """Test user-related endpoints"""
    test_endpoint(f"{API_V1}/users/profile/", auth=auth, description="User Profile")
    test_endpoint(f"{API_V1}/users/addresses/", auth=auth, description="User Addresses")

def test_cart_endpoints(auth=False):
    """Test cart-related endpoints"""
    test_endpoint(f"{API_V1}/cart/", auth=auth, description="Cart Contents")

def test_order_endpoints(auth=False):
    """Test order-related endpoints"""
    test_endpoint(f"{API_V1}/orders/", auth=auth, description="User Orders")

def main():
    """Main function to run tests"""
    print("===== JOULINA API TESTING =====")
    
    # Test product endpoints (no auth required)
    test_product_endpoints()
    
    # Ask if user wants to test authenticated endpoints
    test_auth = input("\nDo you want to test authenticated endpoints? (y/n): ").lower() == 'y'
    
    if test_auth:
        username = input("Username: ")
        password = input("Password: ")
        login(username, password)
        
        if TOKEN:
            test_user_endpoints(auth=True)
            test_cart_endpoints(auth=True)
            test_order_endpoints(auth=True)
    
    print("\n===== API TESTING COMPLETE =====")

if __name__ == "__main__":
    main() 