-- =============================================
-- POS System Database Schema - Indexes
-- Version: 1.0
-- Author: Mangesh Bhattacharya
-- Performance optimization through strategic indexing
-- =============================================

USE POSReporting;
GO

PRINT 'Creating indexes for performance optimization...';
GO

-- =============================================
-- Transactions Table Indexes
-- =============================================

-- Index on TransactionDate for date range queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Transactions_Date' AND object_id = OBJECT_ID('Transactions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Transactions_Date 
    ON Transactions(TransactionDate DESC)
    INCLUDE (TotalAmount, NetAmount, GrossAmount, StoreID, EmployeeID);
    PRINT 'Index IX_Transactions_Date created';
END
GO

-- Index on StoreID for store-specific reports
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Transactions_Store' AND object_id = OBJECT_ID('Transactions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Transactions_Store 
    ON Transactions(StoreID, TransactionDate DESC)
    INCLUDE (TotalAmount, NetAmount, EmployeeID);
    PRINT 'Index IX_Transactions_Store created';
END
GO

-- Index on EmployeeID for employee performance reports
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Transactions_Employee' AND object_id = OBJECT_ID('Transactions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Transactions_Employee 
    ON Transactions(EmployeeID, TransactionDate DESC)
    INCLUDE (TotalAmount, NetAmount);
    PRINT 'Index IX_Transactions_Employee created';
END
GO

-- Index on CustomerID for customer analytics
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Transactions_Customer' AND object_id = OBJECT_ID('Transactions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Transactions_Customer 
    ON Transactions(CustomerID, TransactionDate DESC)
    WHERE CustomerID IS NOT NULL;
    PRINT 'Index IX_Transactions_Customer created';
END
GO

-- Index on PaymentMethod for payment analysis
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Transactions_PaymentMethod' AND object_id = OBJECT_ID('Transactions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Transactions_PaymentMethod 
    ON Transactions(PaymentMethod, TransactionDate DESC)
    INCLUDE (TotalAmount);
    PRINT 'Index IX_Transactions_PaymentMethod created';
END
GO

-- =============================================
-- TransactionItems Table Indexes
-- =============================================

-- Index on ProductID for product performance reports
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TransactionItems_Product' AND object_id = OBJECT_ID('TransactionItems'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_TransactionItems_Product 
    ON TransactionItems(ProductID, TransactionID)
    INCLUDE (Quantity, UnitPrice, LineTotal, Discount);
    PRINT 'Index IX_TransactionItems_Product created';
END
GO

-- Index on TransactionID for join optimization
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TransactionItems_Transaction' AND object_id = OBJECT_ID('TransactionItems'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_TransactionItems_Transaction 
    ON TransactionItems(TransactionID)
    INCLUDE (ProductID, Quantity, LineTotal);
    PRINT 'Index IX_TransactionItems_Transaction created';
END
GO

-- =============================================
-- Products Table Indexes
-- =============================================

-- Index on DepartmentID for departmental reports
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Products_Department' AND object_id = OBJECT_ID('Products'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Products_Department 
    ON Products(DepartmentID, IsActive)
    INCLUDE (ProductName, SKU, CostPrice, SellingPrice);
    PRINT 'Index IX_Products_Department created';
END
GO

-- Index on SKU for quick product lookup
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Products_SKU' AND object_id = OBJECT_ID('Products'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Products_SKU 
    ON Products(SKU)
    INCLUDE (ProductName, DepartmentID, SellingPrice);
    PRINT 'Index IX_Products_SKU created';
END
GO

-- Index on StockQuantity for inventory alerts
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Products_Stock' AND object_id = OBJECT_ID('Products'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Products_Stock 
    ON Products(StockQuantity, ReorderLevel, IsActive)
    INCLUDE (ProductName, DepartmentID);
    PRINT 'Index IX_Products_Stock created';
END
GO

-- =============================================
-- Employees Table Indexes
-- =============================================

-- Index on StoreID for store employee queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Employees_Store' AND object_id = OBJECT_ID('Employees'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Employees_Store 
    ON Employees(StoreID, IsActive)
    INCLUDE (EmployeeName, Role);
    PRINT 'Index IX_Employees_Store created';
END
GO

-- =============================================
-- Customers Table Indexes
-- =============================================

-- Index on Email for customer lookup
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customers_Email' AND object_id = OBJECT_ID('Customers'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Customers_Email 
    ON Customers(Email)
    WHERE Email IS NOT NULL;
    PRINT 'Index IX_Customers_Email created';
END
GO

-- Index on Phone for customer lookup
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customers_Phone' AND object_id = OBJECT_ID('Customers'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Customers_Phone 
    ON Customers(Phone)
    WHERE Phone IS NOT NULL;
    PRINT 'Index IX_Customers_Phone created';
END
GO

-- Index on LoyaltyPoints for loyalty program queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customers_Loyalty' AND object_id = OBJECT_ID('Customers'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Customers_Loyalty 
    ON Customers(LoyaltyPoints DESC, IsActive)
    INCLUDE (CustomerName, Email);
    PRINT 'Index IX_Customers_Loyalty created';
END
GO

-- =============================================
-- Departments Table Indexes
-- =============================================

-- Index on IsActive for active department queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Departments_Active' AND object_id = OBJECT_ID('Departments'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Departments_Active 
    ON Departments(IsActive)
    INCLUDE (DepartmentName, ParentDepartmentID);
    PRINT 'Index IX_Departments_Active created';
END
GO

-- =============================================
-- AuditLog Table Indexes
-- =============================================

-- Index on TableName and RecordID for audit queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AuditLog_Table_Record' AND object_id = OBJECT_ID('AuditLog'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_AuditLog_Table_Record 
    ON AuditLog(TableName, RecordID, ChangedDate DESC);
    PRINT 'Index IX_AuditLog_Table_Record created';
END
GO

-- Index on ChangedDate for time-based audit queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AuditLog_Date' AND object_id = OBJECT_ID('AuditLog'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_AuditLog_Date 
    ON AuditLog(ChangedDate DESC)
    INCLUDE (TableName, Action, ChangedBy);
    PRINT 'Index IX_AuditLog_Date created';
END
GO

-- =============================================
-- Update Statistics
-- =============================================
UPDATE STATISTICS Transactions WITH FULLSCAN;
UPDATE STATISTICS TransactionItems WITH FULLSCAN;
UPDATE STATISTICS Products WITH FULLSCAN;
UPDATE STATISTICS Employees WITH FULLSCAN;
UPDATE STATISTICS Customers WITH FULLSCAN;
UPDATE STATISTICS Departments WITH FULLSCAN;
GO

PRINT 'All indexes created successfully!';
PRINT 'Statistics updated for optimal query performance.';
GO
