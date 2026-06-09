# project-boundaries.md

## Tech Stack

### Frontend

Flutter 3.44.1

### Backend

Node.js 24.16.0
Express.js 5.2.1

### Database

SQLite v3.52.0

## Included Scope

### 1. User Authentication & Account Management

* User registration with name, email, and password.
* User login using email and password.
* JWT-based session management.
* Password reset via email workflow.
* Session timeout handling.
* Basic account security validations.

### 2. Grocery Inventory Management

* Add grocery items with:

  * Item name
  * Quantity
  * Unit
  * Expiry date
* Update grocery item details.
* Delete grocery items.
* Inventory stock tracking.
* Inventory status calculation:

  * In Stock
  * Low Stock
  * Out of Stock
  * Expiring Soon
* Inventory updates through:

  * Manual edits
  * Recipe consumption
  * Grocery purchases

### 3. Recipe Management

* Create recipes.
* Edit recipes.
* Delete recipes.
* Store recipe metadata:

  * Name
  * Ingredients
  * Preparation steps
  * Servings
  * Preparation time
* Ingredient validation against inventory.
* Missing ingredient identification.

### 4. Meal Planning

* Daily meal planning.
* Weekly meal planning.
* Meal categories:

  * Breakfast
  * Lunch
  * Dinner
  * Snacks
* Drag-and-drop meal scheduling.
* Automatic persistence of meal plans.
* Inventory validation during planning.

### 5. Shopping List Management

* Missing ingredient detection.
* Automatic shopping list generation.
* Ingredient quantity aggregation.
* Shopping list editing.
* Custom item addition.
* Duplicate item consolidation.

### 6. Grocery Ordering

* Convert shopping list into cart.
* Cart management.
* Delivery address selection.
* Payment method selection.
* Order placement.
* Order history.
* Order tracking.

Supported order statuses:

* Pending
* Confirmed
* Packed
* Out for Delivery
* Delivered
* Cancelled

### 8. Dashboard & Reporting

* User dashboard displaying:

  * Inventory summary
  * Upcoming meal plans
  * Shopping list summary
  * Order summary
  
---

## Technical Constraints

### Architecture Constraints

* Stateless backend services using JWT authentication.
* Centralized database for users, inventory, recipes, meal plans, shopping lists, and orders.
* API-driven architecture for frontend-backend communication.

### Integration Constraints

* Grocery ordering depends on third-party grocery vendors.
* Payment processing relies on external payment gateways.
* Email delivery relies on external email service providers.
* Order tracking depends on partner APIs.

### Data Constraints

* Inventory accuracy depends on user-maintained data.
* Ingredient validation only works against available inventory records.
* Vendor inventory and pricing data may not be real-time.

### Performance Constraints

* Shopping list generation should complete within acceptable user wait times.
* Order tracking updates may be delayed by external systems.

### Security Constraints

* Passwords must be securely hashed.
* JWT tokens must be validated on protected APIs.
* Sensitive user and payment-related data must be encrypted in transit.
* Access control enforced per authenticated user.

---

## Assumptions

### User Assumptions

* Users have internet connectivity.
* Users maintain inventory data accurately.
* Users create and manage their own recipes.
* Users provide valid delivery addresses.
* Users have access to supported payment methods.

### Business Assumptions

* Grocery vendor integrations are available.
* Vendor APIs provide product availability and order status.
* Delivery services are managed by external partners.
* Regional grocery availability varies.

### Technical Assumptions

* Email service is available for account recovery.
* Third-party payment services remain operational.
* External vendor APIs provide acceptable uptime.
* Database storage can scale with user growth.

---

## Risks

### Business Risks

* Low user adoption of inventory tracking due to manual effort.
* Dependence on grocery partners for order fulfillment.
* Regional limitations reducing ordering availability.
* Vendor API changes affecting integrations.

### Technical Risks

* Inventory inaccuracies caused by manual user updates.
* Synchronization delays causing stock mismatches.
* Third-party service outages impacting:

  * Payments
  * Email delivery
  * Grocery ordering
* Drag-and-drop planner issues across devices and browsers.

### Operational Risks

* Partial order fulfillment by vendors.
* Delivery delays outside platform control.
* Inconsistent vendor inventory information.
* Order cancellation conflicts after dispatch.

### Data Risks

* Duplicate grocery records.
* Unit conversion inconsistencies.
* Recipe-to-inventory quantity mismatches.
* Large inventory datasets affecting performance.

