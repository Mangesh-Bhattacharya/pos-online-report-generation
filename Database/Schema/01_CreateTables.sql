-- =============================================
-- POS System Database Schema - Tables
-- Version: 1.0
-- Author: Mangesh Bhattacharya
-- =============================================

USE master;
GO

-- Create Database if not exists
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'POSReporting')
BEGIN
    CREATE DATABASE POSReporting;
END
GO

USE POSReporting;
GO

-- =============================================
-- Departments/Categories Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Departments]') AND type in (N'U'))
BEGIN
    CREATE TABLE Departments (
        DepartmentID INT PRIMARY KEY IDENTITY(1,1),
        DepartmentName NVARCHAR(100) NOT NULL,
        ParentDepartmentID INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME DEFAULT GETDATE(),
        UpdatedDate DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_Departments_Parent FOREIGN KEY (ParentDepartmentID) 
            REFERENCES Departments(DepartmentID)
    );
    
    PRINT 'Table Departments created successfully';
END
GO

-- =============================================
-- Stores Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Stores]') AND type in (N'U'))
BEGIN
    CREATE TABLE Stores (
        StoreID INT PRIMARY KEY IDENTITY(1,1),
        StoreName NVARCHAR(100) NOT NULL,
        Location NVARCHAR(200),
        Address NVARCHAR(500),
        City NVARCHAR(100),
        State NVARCHAR(50),
        ZipCode NVARCHAR(20),
        Phone NVARCHAR(20),
        ManagerID INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME DEFAULT GETDATE(),
        UpdatedDate DATETIME DEFAULT GETDATE()
    );
    
    PRINT 'Table Stores created successfully';
END
GO

-- =============================================
-- Employees Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Employees]') AND type in (N'U'))
BEGIN
    CREATE TABLE Employees (
        EmployeeID INT PRIMARY KEY IDENTITY(1,1),
        EmployeeName NVARCHAR(100) NOT NULL,
        Email NVARCHAR(100),
        Phone NVARCHAR(20),
        Role NVARCHAR(50),
        StoreID INT NOT NULL,
        IsActive BIT DEFAULT 1,
        HireDate DATETIME DEFAULT GETDATE(),
        TerminationDate DATETIME NULL,
        CreatedDate DATETIME DEFAULT GETDATE(),
        UpdatedDate DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_Employees_Store FOREIGN KEY (StoreID) 
            REFERENCES Stores(StoreID)
    );
    
    PRINT 'Table Employees created successfully';
END
GO

-- =============================================
-- Products Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Products]') AND type in (N'U'))
BEGIN
    CREATE TABLE Products (
        ProductID INT PRIMARY KEY IDENTITY(1,1),
        ProductName NVARCHAR(200) NOT NULL,
        SKU NVARCHAR(50) UNIQUE NOT NULL,
        Barcode NVARCHAR(50),
        DepartmentID INT NOT NULL,
        CostPrice DECIMAL(10,2) NOT NULL,
        SellingPrice DECIMAL(10,2) NOT NULL,
        StockQuantity INT DEFAULT 0,
        ReorderLevel INT DEFAULT 10,
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME DEFAULT GETDATE(),
        UpdatedDate DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_Products_Department FOREIGN KEY (DepartmentID) 
            REFERENCES Departments(DepartmentID)
    );
    
    PRINT 'Table Products created successfully';
END
GO

-- =============================================
-- Customers Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customers]') AND type in (N'U'))
BEGIN
    CREATE TABLE Customers (
        CustomerID INT PRIMARY KEY IDENTITY(1,1),
        CustomerName NVARCHAR(100),
        Email NVARCHAR(100),
        Phone NVARCHAR(20),
        Address NVARCHAR(500),
        City NVARCHAR(100),
        State NVARCHAR(50),
        ZipCode NVARCHAR(20),
        LoyaltyPoints INT DEFAULT 0,
        TotalPurchases DECIMAL(10,2) DEFAULT 0,
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME DEFAULT GETDATE(),
        UpdatedDate DATETIME DEFAULT GETDATE()
    );
    
    PRINT 'Table Customers created successfully';
END
GO

-- =============================================
-- Transactions Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Transactions]') AND type in (N'U'))
BEGIN
    CREATE TABLE Transactions (
        TransactionID INT PRIMARY KEY IDENTITY(1,1),
        TransactionNumber NVARCHAR(50) UNIQUE NOT NULL,
        TransactionDate DATETIME NOT NULL DEFAULT GETDATE(),
        TotalAmount DECIMAL(10,2) NOT NULL,
        NetAmount DECIMAL(10,2) NOT NULL,
        GrossAmount DECIMAL(10,2) NOT NULL,
        TaxAmount DECIMAL(10,2) DEFAULT 0,
        DiscountAmount DECIMAL(10,2) DEFAULT 0,
        PaymentMethod NVARCHAR(50),
        PaymentStatus NVARCHAR(20) DEFAULT 'Completed',
        EmployeeID INT NOT NULL,
        StoreID INT NOT NULL,
        CustomerID INT NULL,
        Notes NVARCHAR(500),
        CreatedDate DATETIME DEFAULT GETDATE(),
        UpdatedDate DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_Transactions_Employee FOREIGN KEY (EmployeeID) 
            REFERENCES Employees(EmployeeID),
        CONSTRAINT FK_Transactions_Store FOREIGN KEY (StoreID) 
            REFERENCES Stores(StoreID),
        CONSTRAINT FK_Transactions_Customer FOREIGN KEY (CustomerID) 
            REFERENCES Customers(CustomerID)
    );
    
    PRINT 'Table Transactions created successfully';
END
GO

-- =============================================
-- Transaction Items Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TransactionItems]') AND type in (N'U'))
BEGIN
    CREATE TABLE TransactionItems (
        TransactionItemID INT PRIMARY KEY IDENTITY(1,1),
        TransactionID INT NOT NULL,
        ProductID INT NOT NULL,
        Quantity INT NOT NULL,
        UnitPrice DECIMAL(10,2) NOT NULL,
        Discount DECIMAL(10,2) DEFAULT 0,
        DiscountPercent DECIMAL(5,2) DEFAULT 0,
        LineTotal DECIMAL(10,2) NOT NULL,
        TaxAmount DECIMAL(10,2) DEFAULT 0,
        CreatedDate DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_TransactionItems_Transaction FOREIGN KEY (TransactionID) 
            REFERENCES Transactions(TransactionID) ON DELETE CASCADE,
        CONSTRAINT FK_TransactionItems_Product FOREIGN KEY (ProductID) 
            REFERENCES Products(ProductID)
    );
    
    PRINT 'Table TransactionItems created successfully';
END
GO

-- =============================================
-- Audit Log Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AuditLog]') AND type in (N'U'))
BEGIN
    CREATE TABLE AuditLog (
        AuditID INT PRIMARY KEY IDENTITY(1,1),
        TableName NVARCHAR(100) NOT NULL,
        RecordID INT NOT NULL,
        Action NVARCHAR(20) NOT NULL, -- INSERT, UPDATE, DELETE
        OldValue NVARCHAR(MAX),
        NewValue NVARCHAR(MAX),
        ChangedBy NVARCHAR(100),
        ChangedDate DATETIME DEFAULT GETDATE()
    );
    
    PRINT 'Table AuditLog created successfully';
END
GO

PRINT 'All tables created successfully!';
GO
