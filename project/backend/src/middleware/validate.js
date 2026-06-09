const rules = {
  required: (val, name) => (val === undefined || val === null || val === '' ? `${name} is required` : null),
  email: (val) => {
    if (val === undefined || val === null || val === '') return null;
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return !re.test(val) ? 'Invalid email format' : null;
  },
  minLen: (len) => (val, name) => (val && val.length < len ? `${name} must be at least ${len} characters` : null),
  minVal: (min) => (val, name) => (val !== undefined && val !== null && val < min ? `${name} cannot be negative` : null),
  positive: (val, name) => (val !== undefined && val !== null && val <= 0 ? `${name} must be greater than 0` : null),
  date: (val, name) => {
    if (!val) return null;
    const date = new Date(val);
    return isNaN(date.getTime()) ? `Invalid ${name} date format` : null;
  },
  futureOrToday: (val, name) => {
    if (!val) return null;
    const date = new Date(val);
    if (isNaN(date.getTime())) return `Invalid ${name} date format`;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return date < today ? `${name} cannot be in the past` : null;
  },
  oneOf: (allowed) => (val, name) => (val && !allowed.includes(val) ? `${name} must be one of: ${allowed.join(', ')}` : null),
  nonEmptyArray: (val, name) => (!Array.isArray(val) || val.length === 0 ? `${name} must be a non-empty array` : null)
};

function validate(schema) {
  return (req, res, next) => {
    const details = [];
    for (const [key, fieldRules] of Object.entries(schema)) {
      const val = req.body[key];
      for (const rule of fieldRules) {
        const err = rule(val, key, req.body);
        if (err) {
          details.push({ field: key, message: err });
          break; // Stop evaluating rules for this field if one fails
        }
      }
    }

    if (details.length > 0) {
      return res.status(400).json({
        error: 'Validation failed',
        details
      });
    }
    next();
  };
}

// Custom validator for recipe ingredients
function validateRecipeIngredients(req, res, next) {
  const { ingredients } = req.body;
  if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
    return res.status(400).json({
      error: 'Validation failed',
      details: [{ field: 'ingredients', message: 'ingredients must be a non-empty array' }]
    });
  }

  const details = [];
  ingredients.forEach((ing, index) => {
    if (!ing.ingredientName) {
      details.push({ field: `ingredients[${index}].ingredientName`, message: 'ingredientName is required' });
    }
    if (ing.quantity === undefined || ing.quantity === null || ing.quantity <= 0) {
      details.push({ field: `ingredients[${index}].quantity`, message: 'quantity must be greater than 0' });
    }
    if (!ing.unit) {
      details.push({ field: `ingredients[${index}].unit`, message: 'unit is required' });
    }
  });

  if (details.length > 0) {
    return res.status(400).json({
      error: 'Validation failed',
      details
    });
  }
  next();
}

const schemas = {
  register: {
    name: [rules.required],
    email: [rules.required, rules.email],
    password: [rules.required, rules.minLen(8)]
  },
  login: {
    email: [rules.required],
    password: [rules.required]
  },
  passwordResetRequest: {
    email: [rules.required, rules.email]
  },
  passwordReset: {
    token: [rules.required],
    newPassword: [rules.required, rules.minLen(8)]
  },
  grocery: {
    itemName: [rules.required],
    quantity: [rules.required, rules.minVal(0)],
    unit: [rules.required],
    expiryDate: [rules.futureOrToday]
  },
  groceryUpdate: {
    quantity: [rules.minVal(0)]
  },
  recipe: {
    recipeName: [rules.required],
    servings: [rules.required, rules.positive]
  },
  mealPlan: {
    startDate: [rules.required, rules.date],
    endDate: [rules.required, rules.date]
  },
  mealPlanItem: {
    mealDate: [rules.required, rules.date],
    mealType: [rules.required, rules.oneOf(['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'])],
    recipeId: [rules.required, rules.positive]
  },
  shoppingListCustom: {
    itemName: [rules.required],
    quantity: [rules.required, rules.positive],
    unit: [rules.required]
  },
  shoppingListUpdate: {
    quantity: [rules.positive]
  },
  orderCart: {
    shoppingListItemIds: [rules.required, rules.nonEmptyArray]
  },
  orderCreate: {
    shoppingListId: [rules.required],
    deliveryAddress: [rules.required, rules.minLen(3)],
    paymentMethod: [rules.required, rules.oneOf(['CARD', 'CASH', 'UPI', 'PAYPAL'])]
  }
};

module.exports = {
  validate,
  validateRecipeIngredients,
  schemas
};
