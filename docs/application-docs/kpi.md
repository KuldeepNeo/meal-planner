# Meal Planner Application – KPI Validation Document

## Module 1: User Registration & Authentication

### Validation Functions Table

| KPI Number   | KPI                                                                 | Validation Method                                                                                                                                                                    |
| ------------ | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| KPI-AUTH-001 | User can successfully register with valid name, email, and password | Submit POST `/api/auth/register` with valid payload, verify HTTP success response, userId returned, user record created in database, and dashboard access granted after registration |
| KPI-AUTH-002 | System prevents duplicate email registration                        | Submit POST `/api/auth/register` using an existing email, verify validation error response, no duplicate database record created, and appropriate error message displayed            |
| KPI-AUTH-003 | System validates mandatory registration fields                      | Submit registration requests with missing name, email, or password individually, verify validation errors returned and no account creation occurs                                    |
| KPI-AUTH-004 | User can successfully login with valid credentials                  | Submit POST `/api/auth/login` with valid credentials, verify JWT token and refresh token returned, session created, and dashboard access granted                                     |
| KPI-AUTH-005 | System rejects invalid login credentials                            | Submit login request with invalid email or password, verify authentication failure response and no session token generated                                                           |
| KPI-AUTH-006 | JWT token is generated after successful authentication              | Verify login response contains valid JWT token, token structure is correct, and token can access protected APIs                                                                      |
| KPI-AUTH-007 | User can initiate password reset process                            | Submit password reset request with registered email, verify reset link generation and delivery workflow execution                                                                    |
| KPI-AUTH-008 | User can reset password using valid reset link                      | Open valid reset link, submit new password, verify password update in database and successful login with new credentials                                                             |
| KPI-AUTH-009 | System rejects expired password reset links                         | Attempt password reset using expired token, verify reset failure and password remains unchanged                                                                                      |
| KPI-AUTH-010 | Session timeout is enforced correctly                               | Create authenticated session, allow timeout period to expire, verify protected APIs return unauthorized response                                                                     |
| KPI-AUTH-011 | Multiple concurrent sessions are handled correctly                  | Login from multiple devices simultaneously, verify session behavior follows defined authentication rules and tokens remain valid                                                     |

---

# Module 2: Grocery Inventory Management

### Validation Functions Table

| KPI Number   | KPI                                                 | Validation Method                                                                                                                    |
| ------------ | --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| KPI-GROC-001 | User can add grocery item with valid details        | Submit POST `/api/groceries` with item name, quantity, unit, and expiry date, verify item creation in database and inventory listing |
| KPI-GROC-002 | System validates mandatory grocery fields           | Submit grocery creation request with missing required fields, verify validation error response and no database record created        |
| KPI-GROC-003 | System rejects negative quantity values             | Submit grocery item with negative quantity, verify validation failure and item not saved                                             |
| KPI-GROC-004 | System rejects invalid expiry dates                 | Submit grocery item with invalid or past expiry date format, verify validation error response                                        |
| KPI-GROC-005 | User can update grocery item details                | Submit PUT `/api/groceries/{id}` with updated quantity or attributes, verify inventory record updated correctly                      |
| KPI-GROC-006 | User can delete grocery item                        | Submit DELETE `/api/groceries/{id}`, verify item removed from database and inventory list                                            |
| KPI-GROC-007 | Inventory list displays all grocery items           | Execute GET `/api/groceries`, verify all stored inventory records are returned accurately                                            |
| KPI-GROC-008 | Inventory updates after manual modification         | Modify inventory quantities manually and verify changes persist across API and UI                                                    |
| KPI-GROC-009 | Inventory updates after recipe consumption          | Execute recipe usage workflow and verify ingredient quantities decrease correctly in inventory                                       |
| KPI-GROC-010 | Inventory updates after grocery purchase            | Complete grocery purchase workflow and verify purchased items increase inventory quantities correctly                                |
| KPI-GROC-011 | System correctly identifies In Stock status         | Create inventory above threshold, verify status returned as In Stock                                                                 |
| KPI-GROC-012 | System correctly identifies Low Stock status        | Create inventory below threshold, verify status returned as Low Stock                                                                |
| KPI-GROC-013 | System correctly identifies Out of Stock status     | Set inventory quantity to zero, verify status returned as Out of Stock                                                               |
| KPI-GROC-014 | System correctly identifies Expiring Soon status    | Create inventory item approaching expiry threshold, verify status returned as Expiring Soon                                          |
| KPI-GROC-015 | System handles duplicate grocery items consistently | Create duplicate grocery entries and verify duplicate handling follows business rules                                                |
| KPI-GROC-016 | System supports large inventory volumes             | Load extremely large inventory dataset, verify API responses, UI rendering, and data integrity remain stable                         |

---

# Module 3: Recipe Management

### Validation Functions Table

| KPI Number     | KPI                                                      | Validation Method                                                                                                 |
| -------------- | -------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| KPI-RECIPE-001 | User can create recipe with valid data                   | Submit POST `/api/recipes` with valid recipe details, verify recipe saved in database and retrievable through API |
| KPI-RECIPE-002 | System validates mandatory recipe fields                 | Submit recipe creation request with missing required fields, verify validation errors and no record creation      |
| KPI-RECIPE-003 | Recipe name is mandatory                                 | Submit recipe creation request without recipe name, verify validation failure                                     |
| KPI-RECIPE-004 | Ingredient list is mandatory                             | Submit recipe creation request with empty ingredient list, verify validation failure                              |
| KPI-RECIPE-005 | User can update recipe information                       | Submit PUT `/api/recipes/{id}` with modified details, verify recipe updated successfully                          |
| KPI-RECIPE-006 | User can delete recipe                                   | Submit DELETE `/api/recipes/{id}`, verify recipe removed from database                                            |
| KPI-RECIPE-007 | System validates recipe ingredients against inventory    | Execute POST `/api/recipes/validate`, verify inventory lookup and validation result accuracy                      |
| KPI-RECIPE-008 | System confirms ingredient existence in inventory        | Validate recipe containing existing ingredients, verify successful validation response                            |
| KPI-RECIPE-009 | System detects missing inventory ingredients             | Validate recipe containing unavailable ingredients, verify missing ingredients flagged correctly                  |
| KPI-RECIPE-010 | System verifies required ingredient quantities           | Validate recipe quantities against inventory levels and verify availability calculations                          |
| KPI-RECIPE-011 | System flags insufficient ingredient quantities          | Validate recipe exceeding inventory quantities, verify shortage notification generated                            |
| KPI-RECIPE-012 | System detects ingredient quantity mismatch              | Submit recipe with inconsistent ingredient quantities and verify validation response                              |
| KPI-RECIPE-013 | System handles deleted ingredients referenced by recipes | Delete inventory ingredient used by recipe and verify recipe validation identifies missing reference              |

---

# Module 4: Meal Planning

### Validation Functions Table

| KPI Number   | KPI                                                        | Validation Method                                                                                  |
| ------------ | ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| KPI-MEAL-001 | User can create daily meal plan                            | Submit POST `/api/meal-plans` for a specific date, verify meal plan persistence and retrieval      |
| KPI-MEAL-002 | User can create weekly meal plan                           | Create meal plan covering multiple dates and verify all planned meals are stored correctly         |
| KPI-MEAL-003 | User can assign recipes to breakfast slots                 | Schedule recipe into breakfast slot and verify assignment persistence                              |
| KPI-MEAL-004 | User can assign recipes to lunch slots                     | Schedule recipe into lunch slot and verify assignment persistence                                  |
| KPI-MEAL-005 | User can assign recipes to dinner slots                    | Schedule recipe into dinner slot and verify assignment persistence                                 |
| KPI-MEAL-006 | User can assign recipes to snack slots                     | Schedule recipe into snack slot and verify assignment persistence                                  |
| KPI-MEAL-007 | Inventory validation occurs during meal planning           | Create meal plan using recipes and verify inventory availability check executes                    |
| KPI-MEAL-008 | System detects insufficient inventory during meal planning | Create meal plan requiring unavailable ingredients and verify warning generated                    |
| KPI-MEAL-009 | User can update meal plans                                 | Submit PUT `/api/meal-plans/{id}`, verify modifications saved correctly                            |
| KPI-MEAL-010 | User can delete meal plans                                 | Submit DELETE `/api/meal-plans/{id}`, verify plan removal from database                            |
| KPI-MEAL-011 | Drag-and-drop scheduling updates UI instantly              | Drag recipe card to new meal slot, verify immediate UI state update without page refresh           |
| KPI-MEAL-012 | Drag-and-drop scheduling persists changes automatically    | Perform drag-and-drop operation, refresh application, verify updated schedule remains stored       |
| KPI-MEAL-013 | System handles recipe scheduled multiple times             | Schedule identical recipe across multiple slots and verify business rule compliance                |
| KPI-MEAL-014 | Planner synchronization remains consistent across sessions | Update planner from one session and verify synchronized data across other sessions                 |
| KPI-MEAL-015 | Drag-and-drop failures are handled gracefully              | Simulate drag-and-drop persistence failure and verify user receives appropriate error notification |

---

# Module 5: Shopping List Management

### Validation Functions Table

| KPI Number   | KPI                                                                  | Validation Method                                                                                                     |
| ------------ | -------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| KPI-SHOP-001 | Missing ingredients are identified from meal plans                   | Create meal plan with unavailable ingredients, generate shopping list, verify missing ingredients detected accurately |
| KPI-SHOP-002 | Ingredient requirements are calculated correctly                     | Generate shopping list from multiple recipes, verify required quantities match recipe requirements                    |
| KPI-SHOP-003 | Inventory availability is considered during shopping list generation | Compare recipe requirements against inventory and verify only missing quantities appear in shopping list              |
| KPI-SHOP-004 | Shopping list is generated successfully                              | Execute GET `/api/shopping-list`, verify shopping list creation and correct item inclusion                            |
| KPI-SHOP-005 | Duplicate ingredients are aggregated correctly                       | Generate shopping list with duplicate ingredients across recipes and verify quantity aggregation                      |
| KPI-SHOP-006 | Shopping list quantities are calculated accurately                   | Validate generated quantities against recipe consumption and inventory levels                                         |
| KPI-SHOP-007 | User can manually edit generated shopping list                       | Modify generated shopping list items and verify updates persist                                                       |
| KPI-SHOP-008 | User can remove shopping list items                                  | Delete item from shopping list and verify removal persists                                                            |
| KPI-SHOP-009 | User can add custom shopping list items                              | Submit POST `/api/shopping-list/custom-item`, verify item added successfully                                          |
| KPI-SHOP-010 | System handles unit conversion conflicts correctly                   | Generate shopping list containing mixed units and verify conversion logic or conflict handling                        |
| KPI-SHOP-011 | System identifies ingredients unavailable from vendor                | Generate shopping list containing unavailable vendor items and verify availability warnings displayed                 |

---

# Module 6: Grocery Ordering

### Validation Functions Table

| KPI Number    | KPI                                                          | Validation Method                                                                           |
| ------------- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| KPI-ORDER-001 | User can add shopping list items to cart                     | Submit POST `/api/orders/cart`, verify selected items appear in cart                        |
| KPI-ORDER-002 | Cart accurately reflects selected shopping list items        | Compare shopping list selection against cart contents and verify exact match                |
| KPI-ORDER-003 | User can place grocery order with valid details              | Submit POST `/api/orders` with valid address and payment method, verify order creation      |
| KPI-ORDER-004 | Delivery address validation is enforced                      | Submit invalid delivery address during checkout and verify validation failure               |
| KPI-ORDER-005 | Payment method validation is enforced                        | Submit invalid payment information and verify checkout rejection                            |
| KPI-ORDER-006 | Successful order generates order record                      | Complete checkout successfully and verify order stored in database                          |
| KPI-ORDER-007 | User can retrieve order history                              | Execute GET `/api/orders`, verify all user orders are returned accurately                   |
| KPI-ORDER-008 | User can retrieve order details                              | Execute GET `/api/orders/{id}`, verify complete order information returned                  |
| KPI-ORDER-009 | User can track order status                                  | Execute GET `/api/orders/{id}/tracking`, verify current tracking information returned       |
| KPI-ORDER-010 | System supports Pending order status                         | Create order and verify Pending status is available and displayed correctly                 |
| KPI-ORDER-011 | System supports Confirmed order status                       | Update order lifecycle and verify Confirmed status handling                                 |
| KPI-ORDER-012 | System supports Packed order status                          | Update order lifecycle and verify Packed status handling                                    |
| KPI-ORDER-013 | System supports Out for Delivery status                      | Update order lifecycle and verify Out for Delivery status handling                          |
| KPI-ORDER-014 | System supports Delivered order status                       | Complete order lifecycle and verify Delivered status handling                               |
| KPI-ORDER-015 | System supports Cancelled order status                       | Cancel eligible order and verify Cancelled status handling                                  |
| KPI-ORDER-016 | Payment failures are handled correctly                       | Simulate payment failure and verify order not completed and error returned                  |
| KPI-ORDER-017 | Inventory unavailability after checkout is handled correctly | Simulate inventory shortage after order placement and verify appropriate workflow execution |
| KPI-ORDER-018 | Partial order fulfillment is supported                       | Create order with partially available inventory and verify fulfillment tracking accuracy    |
| KPI-ORDER-019 | Order cancellation after dispatch follows business rules     | Attempt cancellation after dispatch and verify system response matches defined rules        |
| KPI-ORDER-020 | Estimated delivery information is displayed                  | Retrieve tracked order and verify estimated delivery information is available               |
| KPI-ORDER-021 | Delivery updates are displayed accurately                    | Update tracking events and verify real-time delivery updates appear correctly               |

---

# Module 7: API Reliability & Data Integrity

### Validation Functions Table

| KPI Number  | KPI                                                   | Validation Method                                                                                                                                    |
| ----------- | ----------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| KPI-API-001 | All documented APIs return valid HTTP responses       | Execute all PRD-defined API endpoints and verify expected status codes and payload structures                                                        |
| KPI-API-002 | API data persists correctly in database               | Create, update, and delete records through APIs and verify database consistency                                                                      |
| KPI-API-003 | Unauthorized requests are rejected                    | Execute protected APIs without valid JWT token and verify unauthorized response                                                                      |
| KPI-API-004 | Invalid request payloads are handled gracefully       | Submit malformed API requests and verify validation responses without system failure                                                                 |
| KPI-API-005 | API responses maintain schema consistency             | Verify API responses match documented request and response contracts                                                                                 |
| KPI-API-006 | Concurrent transactions maintain data integrity       | Execute simultaneous updates against shared resources and verify no data corruption occurs                                                           |
| KPI-API-007 | System maintains referential integrity across modules | Create linked records across inventory, recipes, meal plans, shopping lists, and orders; verify relationship consistency after updates and deletions |

---

# Module 8: Product Success Metrics Validation

### Validation Functions Table

| KPI Number  | KPI                                                | Validation Method                                                                                                                 |
| ----------- | -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| KPI-BUS-001 | Weekly Meal Plan Creation Rate exceeds 70%         | Calculate percentage of active users creating at least one weekly meal plan during reporting period and verify result exceeds 70% |
| KPI-BUS-002 | Grocery Tracking Usage exceeds 80%                 | Calculate percentage of active users performing inventory management actions and verify usage exceeds 80%                         |
| KPI-BUS-003 | Recipe Creation Rate exceeds 50%                   | Calculate percentage of users creating at least one recipe and verify rate exceeds 50%                                            |
| KPI-BUS-004 | Grocery Order Conversion Rate exceeds 20%          | Measure percentage of shopping list users who complete grocery orders and verify conversion exceeds 20%                           |
| KPI-BUS-005 | User Retention Rate exceeds 60%                    | Calculate retained users over defined retention period and verify rate exceeds 60%                                                |
| KPI-BUS-006 | Average Meal Plans per User per Month is 4 or more | Aggregate monthly meal plan creation metrics and verify average equals or exceeds 4                                               |
| KPI-BUS-007 | Shopping List Generation Rate exceeds 75%          | Calculate percentage of meal plans generating shopping lists and verify rate exceeds 75%                                          |
| KPI-BUS-008 | Inventory Accuracy Rate exceeds 90%                | Compare recorded inventory against verified inventory data and verify accuracy exceeds 90%                                        |
| KPI-BUS-009 | Order Completion Rate exceeds 95%                  | Calculate percentage of successfully completed grocery orders and verify rate exceeds 95%                                         |
| KPI-BUS-010 | Food Waste Reduction exceeds 25%                   | Compare food waste baseline against current reporting period and verify reduction exceeds 25%                                     |
| KPI-BUS-011 | Monthly Active User Growth exceeds 10%             | Compare monthly active user counts across reporting periods and verify growth exceeds 10%                                         |

---

## KPI Summary

* **Authentication KPIs:** 11
* **Grocery Management KPIs:** 16
* **Recipe Management KPIs:** 13
* **Meal Planning KPIs:** 15
* **Shopping List KPIs:** 11
* **Grocery Ordering KPIs:** 21
* **API & Data Integrity KPIs:** 7
* **Business Metrics KPIs:** 11