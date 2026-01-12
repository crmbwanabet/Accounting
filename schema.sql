-- ============================================================
-- BWANABET ACCOUNTING DATABASE SCHEMA
-- Standalone database tables for the Accounting System
-- Run this in your Supabase SQL Editor
-- ============================================================

-- Note: These tables are prefixed with 'acc_' to keep them 
-- separate from the CRM 'players' table

-- ============================================================
-- EXPENSE CATEGORIES
-- ============================================================
CREATE TABLE IF NOT EXISTS acc_expense_categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  color VARCHAR(7) DEFAULT '#6B7280',
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default categories
INSERT INTO acc_expense_categories (key, name, color, sort_order) VALUES
  ('gaming_operations', 'Gaming Operations', '#8B5CF6', 1),
  ('shop_operating', 'Shop Operating Expenses', '#F59E0B', 2),
  ('office_operations', 'Office Operations', '#3B82F6', 3),
  ('administrative', 'Administrative Operations', '#10B981', 4)
ON CONFLICT (key) DO NOTHING;

-- ============================================================
-- EXPENSE SUBCATEGORIES
-- ============================================================
CREATE TABLE IF NOT EXISTS acc_expense_subcategories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  category_id UUID REFERENCES acc_expense_categories(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- EXPENSES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS acc_expenses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  date DATE NOT NULL,
  category_id VARCHAR(50), -- gaming_operations, shop_operating, etc.
  subcategory_id UUID REFERENCES acc_expense_subcategories(id),
  amount DECIMAL(15, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'ZMW',
  amount_base DECIMAL(15, 2), -- Converted to ZMW
  exchange_rate DECIMAL(15, 6),
  vendor VARCHAR(200),
  description TEXT,
  receipt_number VARCHAR(100),
  payment_method VARCHAR(50),
  receipt_url TEXT, -- Supabase storage URL
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- REVENUE TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS acc_revenue (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  date DATE NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'sports', 'casino', 'other'
  amount DECIMAL(15, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'ZMW',
  amount_base DECIMAL(15, 2),
  exchange_rate DECIMAL(15, 6),
  description TEXT,
  reference_number VARCHAR(100),
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- EXCHANGE RATES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS acc_exchange_rates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  base_currency VARCHAR(3) DEFAULT 'ZMW',
  target_currency VARCHAR(3) NOT NULL,
  rate DECIMAL(15, 6) NOT NULL,
  fetched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- AUDIT LOG TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS acc_audit_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id),
  user_email VARCHAR(255),
  action VARCHAR(50) NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id UUID,
  old_values JSONB,
  new_values JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- ACCOUNTING SETTINGS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS acc_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key VARCHAR(100) UNIQUE NOT NULL,
  value JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_acc_expenses_date ON acc_expenses(date);
CREATE INDEX IF NOT EXISTS idx_acc_expenses_category ON acc_expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_acc_revenue_date ON acc_revenue(date);
CREATE INDEX IF NOT EXISTS idx_acc_revenue_type ON acc_revenue(type);
CREATE INDEX IF NOT EXISTS idx_acc_audit_log_timestamp ON acc_audit_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_acc_audit_log_entity ON acc_audit_log(entity_type, entity_id);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE acc_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE acc_revenue ENABLE ROW LEVEL SECURITY;
ALTER TABLE acc_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE acc_expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE acc_expense_subcategories ENABLE ROW LEVEL SECURITY;
ALTER TABLE acc_exchange_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE acc_settings ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- RLS POLICIES (Authenticated users only)
-- ============================================================

-- Expense Categories
CREATE POLICY "Authenticated users can read acc_expense_categories" 
  ON acc_expense_categories FOR SELECT 
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can manage acc_expense_categories" 
  ON acc_expense_categories FOR ALL 
  USING (auth.role() = 'authenticated');

-- Expense Subcategories
CREATE POLICY "Authenticated users can read acc_expense_subcategories" 
  ON acc_expense_subcategories FOR SELECT 
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can manage acc_expense_subcategories" 
  ON acc_expense_subcategories FOR ALL 
  USING (auth.role() = 'authenticated');

-- Expenses
CREATE POLICY "Authenticated users can manage acc_expenses" 
  ON acc_expenses FOR ALL 
  USING (auth.role() = 'authenticated');

-- Revenue
CREATE POLICY "Authenticated users can manage acc_revenue" 
  ON acc_revenue FOR ALL 
  USING (auth.role() = 'authenticated');

-- Audit Log
CREATE POLICY "Authenticated users can read acc_audit_log" 
  ON acc_audit_log FOR SELECT 
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert acc_audit_log" 
  ON acc_audit_log FOR INSERT 
  WITH CHECK (auth.role() = 'authenticated');

-- Exchange Rates
CREATE POLICY "Authenticated users can manage acc_exchange_rates" 
  ON acc_exchange_rates FOR ALL 
  USING (auth.role() = 'authenticated');

-- Settings
CREATE POLICY "Authenticated users can manage acc_settings" 
  ON acc_settings FOR ALL 
  USING (auth.role() = 'authenticated');

-- ============================================================
-- DONE!
-- ============================================================
-- After running this script, you'll have:
-- 1. acc_expense_categories - 4 default categories
-- 2. acc_expense_subcategories - for custom subcategories
-- 3. acc_expenses - all expense records
-- 4. acc_revenue - all revenue records
-- 5. acc_exchange_rates - stored exchange rates
-- 6. acc_audit_log - activity tracking
-- 7. acc_settings - system settings
-- ============================================================
