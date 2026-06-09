# api_contract.md

# Authentication APIs

---

### POST /api/auth/register

#### Purpose

Register a new user account.

#### Request

```json
{
  "name": "John Smith",
  "email": "john@example.com",
  "password": "Password123"
}
```

#### Response

```json
{
  "userId": 1,
  "message": "Registration successful"
}
```

#### Validation Rules

* name required
* email required
* email unique
* valid email format
* password minimum 8 characters

#### Status Codes

| Code | Meaning          |
| ---- | ---------------- |
| 201  | Created          |
| 400  | Validation Error |
| 409  | Duplicate Email  |

#### Error Response

```json
{
  "error": "Email already exists"
}
```

---

### POST /api/auth/login

#### Purpose

Authenticate user.

#### Request

```json
{
  "email": "john@example.com",
  "password": "Password123"
}
```

#### Response

```json
{
  "token": "jwt-token",
  "refreshToken": "refresh-token",
  "userId": 1
}
```

#### Validation Rules

* email required
* password required
* credentials must match

#### Status Codes

| Code | Meaning      |
| ---- | ------------ |
| 200  | Success      |
| 401  | Unauthorized |

#### Error Response

```json
{
  "error": "Invalid credentials"
}
```

---

### POST /api/auth/password-reset-request

#### Purpose

Initiate password reset.

#### Request

```json
{
  "email": "john@example.com"
}
```

#### Response

```json
{
  "message": "Password reset link sent"
}
```

#### Validation Rules

* registered email required

#### Status Codes

| Code | Meaning        |
| ---- | -------------- |
| 200  | Success        |
| 404  | User Not Found |

---

### POST /api/auth/password-reset

#### Purpose

Reset password.

#### Request

```json
{
  "token": "reset-token",
  "newPassword": "Password123"
}
```

#### Response

```json
{
  "message": "Password updated"
}
```

#### Validation Rules

* valid token
* token not expired
* password minimum length

#### Status Codes

| Code | Meaning       |
| ---- | ------------- |
| 200  | Success       |
| 400  | Invalid Token |

---

# Grocery Inventory APIs

---

### GET /api/groceries

#### Purpose

Retrieve inventory items.

#### Response

```json
[
  {
    "id": 1,
    "itemName": "Milk",
    "quantity": 2,
    "unit": "Liter",
    "status": "IN_STOCK"
  }
]
```

#### Status Codes

| Code | Meaning |
| ---- | ------- |
| 200  | Success |

---

### POST /api/groceries

#### Purpose

Create inventory item.

#### Request

```json
{
  "itemName": "Milk",
  "quantity": 2,
  "unit": "Liter",
  "expiryDate": "2026-06-15"
}
```

#### Response

```json
{
  "id": 1
}
```

#### Validation Rules

* itemName required
* quantity >= 0
* unit required
* valid expiry date

#### Status Codes

| Code | Meaning          |
| ---- | ---------------- |
| 201  | Created          |
| 400  | Validation Error |

---

### PUT /api/groceries/{id}

#### Purpose

Update inventory item.

#### Request

```json
{
  "quantity": 5
}
```

#### Response

```json
{
  "message": "Updated"
}
```

#### Status Codes

| Code | Meaning   |
| ---- | --------- |
| 200  | Success   |
| 404  | Not Found |

---

### DELETE /api/groceries/{id}

#### Purpose

Delete inventory item.

#### Response

```json
{
  "message": "Deleted"
}
```

#### Status Codes

| Code | Meaning   |
| ---- | --------- |
| 200  | Success   |
| 404  | Not Found |

---

# Recipe APIs

### GET /api/recipes

### GET /api/recipes/{id}

### POST /api/recipes

#### Request

```json
{
  "recipeName": "Pasta",
  "servings": 4,
  "ingredients": [
    {
      "ingredientName": "Tomato",
      "quantity": 2,
      "unit": "Piece"
    }
  ]
}
```

#### Response

```json
{
  "id": 1
}
```

#### Validation Rules

* recipeName required
* ingredients required
* servings > 0

#### Status Codes

| Code | Meaning          |
| ---- | ---------------- |
| 201  | Created          |
| 400  | Validation Error |

---

### PUT /api/recipes/{id}

### DELETE /api/recipes/{id}

### POST /api/recipes/validate

#### Purpose

Validate recipe against inventory.

#### Request

```json
{
  "recipeId": 1
}
```

#### Response

```json
{
  "valid": false,
  "missingIngredients": [
    "Tomato"
  ]
}
```

---

# Meal Planning APIs

### GET /api/meal-plans

### GET /api/meal-plans/{id}

### POST /api/meal-plans

#### Request

```json
{
  "startDate": "2026-06-09",
  "endDate": "2026-06-15"
}
```

#### Response

```json
{
  "id": 1
}
```

---

### POST /api/meal-plans/{id}/items

#### Request

```json
{
  "mealDate": "2026-06-10",
  "mealType": "BREAKFAST",
  "recipeId": 5
}
```

#### Response

```json
{
  "id": 100
}
```

---

### PUT /api/meal-plans/{id}

### DELETE /api/meal-plans/{id}

---

# Shopping List APIs

### GET /api/shopping-list

#### Purpose

Generate and retrieve shopping list.

#### Response

```json
{
  "shoppingListId": 10,
  "items": [
    {
      "ingredientName": "Tomato",
      "quantity": 4,
      "unit": "Piece"
    }
  ]
}
```

---

### POST /api/shopping-list/custom-item

#### Request

```json
{
  "itemName": "Bread",
  "quantity": 2,
  "unit": "Pack"
}
```

#### Response

```json
{
  "id": 1
}
```

---

### PUT /api/shopping-list/items/{id}

### DELETE /api/shopping-list/items/{id}

---

# Grocery Ordering APIs

### POST /api/orders/cart

#### Purpose

Add shopping list items to cart.

#### Request

```json
{
  "shoppingListItemIds": [1,2,3]
}
```

#### Response

```json
{
  "cartId": 1
}
```

---

### POST /api/orders

#### Purpose

Place grocery order.

#### Request

```json
{
  "shoppingListId": 10,
  "deliveryAddress": "Mumbai",
  "paymentMethod": "CARD"
}
```

#### Response

```json
{
  "orderId": 1001,
  "status": "PENDING"
}
```

#### Validation Rules

* valid address
* valid payment method
* items available

#### Status Codes

| Code | Meaning          |
| ---- | ---------------- |
| 201  | Created          |
| 400  | Validation Error |
| 402  | Payment Failed   |

---

### GET /api/orders

### GET /api/orders/{id}

### GET /api/orders/{id}/tracking

#### Response

```json
{
  "orderId": 1001,
  "status": "OUT_FOR_DELIVERY",
  "estimatedDelivery": "2026-06-09T18:00:00Z",
  "events": [
    {
      "status": "PACKED",
      "time": "2026-06-09T12:00:00Z"
    }
  ]
}
```

---

# Common Error Response

```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "quantity",
      "message": "Quantity cannot be negative"
    }
  ]
}
```

---

# KPI Coverage Mapping

| Module            | KPIs Covered                     |
| ----------------- | -------------------------------- |
| Authentication    | KPI-AUTH-001 to KPI-AUTH-011     |
| Grocery Inventory | KPI-GROC-001 to KPI-GROC-016     |
| Recipe Management | KPI-RECIPE-001 to KPI-RECIPE-013 |
| Meal Planning     | KPI-MEAL-001 to KPI-MEAL-015     |
| Shopping List     | KPI-SHOP-001 to KPI-SHOP-011     |
| Grocery Ordering  | KPI-ORDER-001 to KPI-ORDER-021   |
| API Reliability   | KPI-API-001 to KPI-API-007       |
| Business Metrics  | KPI-BUS-001 to KPI-BUS-011       |
