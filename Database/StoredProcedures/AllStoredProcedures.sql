-- =============================================
-- Stored Procedure: Get Departmental Sales Report
-- Version: 1.0
-- Author: Mangesh Bhattacharya
-- Description: Main report for departmental analysis
-- =============================================

USE POSReporting;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetDepartmentalSales]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetDepartmentalSales];
GO

CREATE PROCEDURE sp_GetDepartmentalSales
    @FromDate DATETIME,
    @ToDate DATETIME,
    @DataType NVARCHAR(20) = 'Net', -- 'Net', 'Gross', or 'Total'
    @StoreID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        d.DepartmentName AS Department,
        d.DepartmentID,
        COUNT(DISTINCT t.TransactionID) AS Items,
        CASE 
            WHEN @DataType = 'Net' THEN SUM(t.NetAmount)
            WHEN @DataType = 'Gross' THEN SUM(t.GrossAmount)
            ELSE SUM(t.TotalAmount)
        END AS TotalSales,
        CASE 
            WHEN @DataType = 'Net' THEN AVG(t.NetAmount)
            WHEN @DataType = 'Gross' THEN AVG(t.GrossAmount)
            ELSE AVG(t.TotalAmount)
        END AS Average,
        SUM(ti.Quantity) AS TotalQuantity,
        SUM(ti.LineTotal - (p.CostPrice * ti.Quantity)) AS GrossProfit,
        CASE 
            WHEN SUM(ti.LineTotal) > 0 
            THEN (SUM(ti.LineTotal - (p.CostPrice * ti.Quantity)) / SUM(ti.LineTotal)) * 100
            ELSE 0
        END AS ProfitMargin
    FROM Transactions t
    INNER JOIN TransactionItems ti ON t.TransactionID = ti.TransactionID
    INNER JOIN Products p ON ti.ProductID = p.ProductID
    INNER JOIN Departments d ON p.DepartmentID = d.DepartmentID
    WHERE t.TransactionDate BETWEEN @FromDate AND @ToDate
        AND (@StoreID IS NULL OR t.StoreID = @StoreID)
        AND d.IsActive = 1
        AND t.PaymentStatus = 'Completed'
    GROUP BY d.DepartmentName, d.DepartmentID
    ORDER BY TotalSales DESC;
END;
GO

PRINT 'Stored Procedure sp_GetDepartmentalSales created successfully';
GO

-- =============================================
-- Stored Procedure: Get Department Details (Drill-down)
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetDepartmentDetails]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetDepartmentDetails];
GO

CREATE PROCEDURE sp_GetDepartmentDetails
    @DepartmentID INT,
    @FromDate DATETIME,
    @ToDate DATETIME,
    @DataType NVARCHAR(20) = 'Net'
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        p.ProductID,
        p.ProductName,
        p.SKU,
        SUM(ti.Quantity) AS QuantitySold,
        CASE 
            WHEN @DataType = 'Net' THEN SUM(ti.LineTotal - (ti.Discount * ti.Quantity))
            WHEN @DataType = 'Gross' THEN SUM(ti.LineTotal)
            ELSE SUM(ti.LineTotal)
        END AS TotalSales,
        AVG(ti.UnitPrice) AS AveragePrice,
        SUM(ti.LineTotal - (p.CostPrice * ti.Quantity)) AS GrossProfit,
        CASE 
            WHEN SUM(ti.LineTotal) > 0 
            THEN (SUM(ti.LineTotal - (p.CostPrice * ti.Quantity)) / SUM(ti.LineTotal)) * 100
            ELSE 0
        END AS ProfitMargin,
        p.StockQuantity AS CurrentStock,
        COUNT(DISTINCT t.TransactionID) AS TransactionCount
    FROM TransactionItems ti
    INNER JOIN Products p ON ti.ProductID = p.ProductID
    INNER JOIN Transactions t ON ti.TransactionID = t.TransactionID
    WHERE p.DepartmentID = @DepartmentID
        AND t.TransactionDate BETWEEN @FromDate AND @ToDate
        AND t.PaymentStatus = 'Completed'
    GROUP BY p.ProductID, p.ProductName, p.SKU, p.StockQuantity
    ORDER BY TotalSales DESC;
END;
GO

PRINT 'Stored Procedure sp_GetDepartmentDetails created successfully';
GO

-- =============================================
-- Stored Procedure: Get Date Range Statistics
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetDateRangeStats]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetDateRangeStats];
GO

CREATE PROCEDURE sp_GetDateRangeStats
    @FromDate DATETIME,
    @ToDate DATETIME,
    @StoreID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        COUNT(DISTINCT TransactionID) AS TotalTransactions,
        SUM(TotalAmount) AS TotalRevenue,
        SUM(NetAmount) AS NetRevenue,
        SUM(GrossAmount) AS GrossRevenue,
        AVG(TotalAmount) AS AverageTransaction,
        SUM(TaxAmount) AS TotalTax,
        SUM(DiscountAmount) AS TotalDiscounts,
        COUNT(DISTINCT CustomerID) AS UniqueCustomers,
        COUNT(DISTINCT EmployeeID) AS ActiveEmployees,
        MAX(TotalAmount) AS HighestTransaction,
        MIN(TotalAmount) AS LowestTransaction
    FROM Transactions
    WHERE TransactionDate BETWEEN @FromDate AND @ToDate
        AND (@StoreID IS NULL OR StoreID = @StoreID)
        AND PaymentStatus = 'Completed';
END;
GO

PRINT 'Stored Procedure sp_GetDateRangeStats created successfully';
GO

-- =============================================
-- Stored Procedure: Get Hourly Sales Trends
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetHourlySalesTrends]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetHourlySalesTrends];
GO

CREATE PROCEDURE sp_GetHourlySalesTrends
    @FromDate DATETIME,
    @ToDate DATETIME,
    @StoreID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        DATEPART(HOUR, TransactionDate) AS Hour,
        COUNT(DISTINCT TransactionID) AS TransactionCount,
        SUM(TotalAmount) AS TotalSales,
        AVG(TotalAmount) AS AverageSale,
        SUM(CASE WHEN CustomerID IS NOT NULL THEN 1 ELSE 0 END) AS RegisteredCustomers,
        SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS WalkInCustomers
    FROM Transactions
    WHERE TransactionDate BETWEEN @FromDate AND @ToDate
        AND (@StoreID IS NULL OR StoreID = @StoreID)
        AND PaymentStatus = 'Completed'
    GROUP BY DATEPART(HOUR, TransactionDate)
    ORDER BY Hour;
END;
GO

PRINT 'Stored Procedure sp_GetHourlySalesTrends created successfully';
GO

-- =============================================
-- Stored Procedure: Get Employee Performance
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetEmployeePerformance]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetEmployeePerformance];
GO

CREATE PROCEDURE sp_GetEmployeePerformance
    @FromDate DATETIME,
    @ToDate DATETIME,
    @StoreID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        e.EmployeeID,
        e.EmployeeName,
        e.Role,
        s.StoreName,
        COUNT(DISTINCT t.TransactionID) AS TransactionsProcessed,
        SUM(t.TotalAmount) AS TotalSales,
        AVG(t.TotalAmount) AS AverageTransactionValue,
        SUM(t.TotalAmount) / NULLIF(COUNT(DISTINCT t.TransactionID), 0) AS SalesPerTransaction,
        SUM(ti.Quantity) AS ItemsSold,
        RANK() OVER (ORDER BY SUM(t.TotalAmount) DESC) AS SalesRank
    FROM Employees e
    INNER JOIN Transactions t ON e.EmployeeID = t.EmployeeID
    INNER JOIN TransactionItems ti ON t.TransactionID = ti.TransactionID
    INNER JOIN Stores s ON e.StoreID = s.StoreID
    WHERE t.TransactionDate BETWEEN @FromDate AND @ToDate
        AND (@StoreID IS NULL OR e.StoreID = @StoreID)
        AND t.PaymentStatus = 'Completed'
        AND e.IsActive = 1
    GROUP BY e.EmployeeID, e.EmployeeName, e.Role, s.StoreName
    ORDER BY TotalSales DESC;
END;
GO

PRINT 'Stored Procedure sp_GetEmployeePerformance created successfully';
GO

-- =============================================
-- Stored Procedure: Get Payment Method Analysis
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetPaymentMethodAnalysis]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetPaymentMethodAnalysis];
GO

CREATE PROCEDURE sp_GetPaymentMethodAnalysis
    @FromDate DATETIME,
    @ToDate DATETIME,
    @StoreID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ISNULL(PaymentMethod, 'Unknown') AS PaymentMethod,
        COUNT(DISTINCT TransactionID) AS TransactionCount,
        SUM(TotalAmount) AS TotalRevenue,
        AVG(TotalAmount) AS AverageTicketSize,
        SUM(TotalAmount) * 100.0 / SUM(SUM(TotalAmount)) OVER() AS PercentageOfTotal,
        MIN(TotalAmount) AS MinTransaction,
        MAX(TotalAmount) AS MaxTransaction
    FROM Transactions
    WHERE TransactionDate BETWEEN @FromDate AND @ToDate
        AND (@StoreID IS NULL OR StoreID = @StoreID)
        AND PaymentStatus = 'Completed'
    GROUP BY PaymentMethod
    ORDER BY TotalRevenue DESC;
END;
GO

PRINT 'Stored Procedure sp_GetPaymentMethodAnalysis created successfully';
GO

-- =============================================
-- Stored Procedure: Get Inventory Turnover
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetInventoryTurnover]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetInventoryTurnover];
GO

CREATE PROCEDURE sp_GetInventoryTurnover
    @FromDate DATETIME,
    @ToDate DATETIME,
    @DepartmentID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        p.ProductID,
        p.ProductName,
        p.SKU,
        d.DepartmentName,
        p.StockQuantity AS CurrentStock,
        p.ReorderLevel,
        CASE 
            WHEN p.StockQuantity <= p.ReorderLevel THEN 'Low Stock'
            WHEN p.StockQuantity = 0 THEN 'Out of Stock'
            ELSE 'In Stock'
        END AS StockStatus,
        SUM(ti.Quantity) AS UnitsSold,
        p.CostPrice * p.StockQuantity AS InventoryValue,
        CASE 
            WHEN p.StockQuantity > 0 
            THEN CAST(SUM(ti.Quantity) AS FLOAT) / p.StockQuantity
            ELSE 0
        END AS TurnoverRatio,
        DATEDIFF(DAY, @FromDate, @ToDate) / NULLIF(SUM(ti.Quantity), 0) AS DaysToSellOne
    FROM Products p
    INNER JOIN Departments d ON p.DepartmentID = d.DepartmentID
    LEFT JOIN TransactionItems ti ON p.ProductID = ti.ProductID
    LEFT JOIN Transactions t ON ti.TransactionID = t.TransactionID 
        AND t.TransactionDate BETWEEN @FromDate AND @ToDate
        AND t.PaymentStatus = 'Completed'
    WHERE p.IsActive = 1
        AND (@DepartmentID IS NULL OR p.DepartmentID = @DepartmentID)
    GROUP BY p.ProductID, p.ProductName, p.SKU, d.DepartmentName, 
             p.StockQuantity, p.ReorderLevel, p.CostPrice
    ORDER BY TurnoverRatio DESC;
END;
GO

PRINT 'Stored Procedure sp_GetInventoryTurnover created successfully';
GO

-- =============================================
-- Stored Procedure: Get Customer Loyalty Metrics
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetCustomerLoyaltyMetrics]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetCustomerLoyaltyMetrics];
GO

CREATE PROCEDURE sp_GetCustomerLoyaltyMetrics
    @FromDate DATETIME,
    @ToDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH CustomerStats AS (
        SELECT 
            c.CustomerID,
            c.CustomerName,
            c.Email,
            c.LoyaltyPoints,
            COUNT(DISTINCT t.TransactionID) AS PurchaseCount,
            SUM(t.TotalAmount) AS TotalSpent,
            AVG(t.TotalAmount) AS AverageOrderValue,
            MIN(t.TransactionDate) AS FirstPurchase,
            MAX(t.TransactionDate) AS LastPurchase,
            DATEDIFF(DAY, MIN(t.TransactionDate), MAX(t.TransactionDate)) AS CustomerLifespanDays
        FROM Customers c
        INNER JOIN Transactions t ON c.CustomerID = t.CustomerID
        WHERE t.TransactionDate BETWEEN @FromDate AND @ToDate
            AND t.PaymentStatus = 'Completed'
        GROUP BY c.CustomerID, c.CustomerName, c.Email, c.LoyaltyPoints
    )
    SELECT 
        CustomerID,
        CustomerName,
        Email,
        LoyaltyPoints,
        PurchaseCount,
        TotalSpent,
        AverageOrderValue,
        FirstPurchase,
        LastPurchase,
        CustomerLifespanDays,
        CASE 
            WHEN PurchaseCount >= 10 THEN 'VIP'
            WHEN PurchaseCount >= 5 THEN 'Loyal'
            WHEN PurchaseCount >= 2 THEN 'Regular'
            ELSE 'New'
        END AS CustomerSegment,
        CASE 
            WHEN CustomerLifespanDays > 0 
            THEN CAST(PurchaseCount AS FLOAT) / (CustomerLifespanDays / 30.0)
            ELSE 0
        END AS PurchaseFrequencyPerMonth
    FROM CustomerStats
    ORDER BY TotalSpent DESC;
END;
GO

PRINT 'Stored Procedure sp_GetCustomerLoyaltyMetrics created successfully';
GO

PRINT 'All stored procedures created successfully!';
GO
