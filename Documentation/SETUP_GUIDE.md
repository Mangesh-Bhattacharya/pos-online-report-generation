# 🚀 Setup Guide - POS Online Report Generation

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Database Setup](#database-setup)
3. [Application Configuration](#application-configuration)
4. [IIS Deployment](#iis-deployment)
5. [Testing](#testing)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software
- **Visual Studio 2019 or later** (Community, Professional, or Enterprise)
- **SQL Server 2016 or later** (Express, Standard, or Enterprise)
- **SQL Server Management Studio (SSMS)** 18.0 or later
- **.NET Framework 4.8** SDK
- **IIS 10.0 or later** (Windows Server 2016+ or Windows 10+)
- **Git** for version control

### Required NuGet Packages
```xml
<packages>
  <package id="Microsoft.AspNet.SignalR" version="2.4.3" />
  <package id="EPPlus" version="6.2.0" />
  <package id="iTextSharp" version="5.5.13.3" />
  <package id="Newtonsoft.Json" version="13.0.3" />
  <package id="jQuery" version="3.6.0" />
  <package id="Bootstrap" version="5.3.0" />
  <package id="Chart.js" version="4.4.0" />
</packages>
```

---

## Database Setup

### Step 1: Create Database

1. Open **SQL Server Management Studio (SSMS)**
2. Connect to your SQL Server instance
3. Run the following scripts in order:

```bash
# Navigate to Database/Schema folder
cd Database/Schema

# Execute scripts
sqlcmd -S localhost -E -i 01_CreateTables.sql
sqlcmd -S localhost -E -i 02_CreateIndexes.sql
```

Or manually execute in SSMS:
- `Database/Schema/01_CreateTables.sql`
- `Database/Schema/02_CreateIndexes.sql`

### Step 2: Create Stored Procedures

```bash
cd Database/StoredProcedures
sqlcmd -S localhost -E -i AllStoredProcedures.sql
```

### Step 3: Insert Sample Data (Optional)

```bash
cd Database/SampleData
sqlcmd -S localhost -E -i InsertSampleData.sql
```

### Step 4: Verify Database Setup

```sql
-- Check tables
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_CATALOG = 'POSReporting';

-- Check stored procedures
SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_CATALOG = 'POSReporting';

-- Check indexes
SELECT name, type_desc FROM sys.indexes 
WHERE object_id = OBJECT_ID('Transactions');
```

---

## Application Configuration

### Step 1: Clone Repository

```bash
git clone https://github.com/Mangesh-Bhattacharya/pos-online-report-generation.git
cd pos-online-report-generation
```

### Step 2: Open Solution in Visual Studio

1. Open `POSReporting.sln` in Visual Studio
2. Right-click solution → **Restore NuGet Packages**
3. Build solution (Ctrl+Shift+B)

### Step 3: Configure Connection String

Edit `Web.config`:

```xml
<connectionStrings>
  <add name="POSDatabase" 
       connectionString="Server=YOUR_SERVER_NAME;Database=POSReporting;Integrated Security=true;" 
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

**For SQL Server Authentication:**
```xml
<connectionStrings>
  <add name="POSDatabase" 
       connectionString="Server=YOUR_SERVER_NAME;Database=POSReporting;User Id=YOUR_USERNAME;Password=YOUR_PASSWORD;" 
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

### Step 4: Configure App Settings

```xml
<appSettings>
  <!-- Export Settings -->
  <add key="ExportPath" value="~/Exports/" />
  <add key="MaxExportRows" value="10000" />
  <add key="EnablePDFExport" value="true" />
  <add key="EnableExcelExport" value="true" />
  
  <!-- Real-time Settings -->
  <add key="EnableSignalR" value="true" />
  <add key="AutoRefreshInterval" value="30000" />
  
  <!-- Security Settings -->
  <add key="RequireAuthentication" value="false" />
  <add key="EnableAuditLog" value="true" />
</appSettings>
```

### Step 5: Configure SignalR

Add to `Startup.cs` (or create if doesn't exist):

```csharp
using Microsoft.Owin;
using Owin;

[assembly: OwinStartup(typeof(POSReporting.Startup))]

namespace POSReporting
{
    public class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            // Enable SignalR
            app.MapSignalR();
        }
    }
}
```

---

## IIS Deployment

### Step 1: Enable IIS Features

**Windows Server:**
```powershell
# Run as Administrator
Install-WindowsFeature -name Web-Server -IncludeManagementTools
Install-WindowsFeature -name Web-Asp-Net45
Install-WindowsFeature -name Web-WebSockets
```

**Windows 10/11:**
1. Control Panel → Programs → Turn Windows features on or off
2. Enable:
   - Internet Information Services
   - World Wide Web Services → Application Development Features → ASP.NET 4.8
   - World Wide Web Services → Application Development Features → WebSocket Protocol

### Step 2: Create Application Pool

1. Open **IIS Manager**
2. Right-click **Application Pools** → Add Application Pool
3. Settings:
   - Name: `POSReportingAppPool`
   - .NET CLR Version: `.NET CLR Version v4.0.30319`
   - Managed Pipeline Mode: `Integrated`
4. Click **OK**

### Step 3: Configure Application Pool

1. Select `POSReportingAppPool`
2. Advanced Settings:
   - Identity: `ApplicationPoolIdentity` (or custom account with DB access)
   - Start Mode: `AlwaysRunning`
   - Idle Time-out: `0` (for real-time features)

### Step 4: Create Website

1. Right-click **Sites** → Add Website
2. Settings:
   - Site name: `POSReporting`
   - Application pool: `POSReportingAppPool`
   - Physical path: `C:\inetpub\wwwroot\POSReporting` (or your path)
   - Binding: HTTP, Port 80 (or custom port)
3. Click **OK**

### Step 5: Set Permissions

```powershell
# Grant IIS_IUSRS read access
icacls "C:\inetpub\wwwroot\POSReporting" /grant "IIS_IUSRS:(OI)(CI)R" /T

# Grant write access to Exports folder
icacls "C:\inetpub\wwwroot\POSReporting\Exports" /grant "IIS_IUSRS:(OI)(CI)M" /T
```

### Step 6: Configure SQL Server Access

**For Windows Authentication:**
1. Open SSMS
2. Security → Logins → New Login
3. Login name: `IIS APPPOOL\POSReportingAppPool`
4. User Mapping: Select `POSReporting` database
5. Database role: `db_datareader`, `db_datawriter`, `db_executor`

**For SQL Authentication:**
- Use credentials in connection string

---

## Testing

### Step 1: Test Database Connection

Create `TestConnection.aspx`:

```aspx
<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data.SqlClient" %>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        string connString = ConfigurationManager.ConnectionStrings["POSDatabase"].ConnectionString;
        try
        {
            using (SqlConnection conn = new SqlConnection(connString))
            {
                conn.Open();
                Response.Write("✅ Database connection successful!");
            }
        }
        catch (Exception ex)
        {
            Response.Write("❌ Connection failed: " + ex.Message);
        }
    }
</script>
```

Navigate to: `http://localhost/TestConnection.aspx`

### Step 2: Test Report Generation

1. Navigate to: `http://localhost/LuttReport.aspx`
2. Select date range
3. Click **Apply**
4. Verify data loads correctly

### Step 3: Test Real-time Updates

1. Open browser console (F12)
2. Check for SignalR connection: `SignalR connected`
3. Verify auto-refresh is working

### Step 4: Test Export Functions

1. Click **Export to Excel**
2. Verify file downloads
3. Test PDF and CSV exports

---

## Troubleshooting

### Issue: Database Connection Failed

**Solution:**
```sql
-- Check SQL Server is running
SELECT @@SERVERNAME;

-- Verify database exists
SELECT name FROM sys.databases WHERE name = 'POSReporting';

-- Check user permissions
SELECT * FROM fn_my_permissions('POSReporting', 'DATABASE');
```

### Issue: SignalR Not Connecting

**Solution:**
1. Verify WebSocket is enabled in IIS
2. Check `Web.config` has SignalR configuration
3. Ensure firewall allows WebSocket connections
4. Check browser console for errors

### Issue: Export Files Not Generating

**Solution:**
```powershell
# Check folder permissions
icacls "C:\inetpub\wwwroot\POSReporting\Exports"

# Create folder if missing
New-Item -Path "C:\inetpub\wwwroot\POSReporting\Exports" -ItemType Directory

# Grant permissions
icacls "C:\inetpub\wwwroot\POSReporting\Exports" /grant "IIS_IUSRS:(OI)(CI)M" /T
```

### Issue: Slow Report Generation

**Solution:**
```sql
-- Update statistics
UPDATE STATISTICS Transactions WITH FULLSCAN;
UPDATE STATISTICS TransactionItems WITH FULLSCAN;

-- Rebuild indexes
ALTER INDEX ALL ON Transactions REBUILD;
ALTER INDEX ALL ON TransactionItems REBUILD;

-- Check query execution plan
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
EXEC sp_GetDepartmentalSales @FromDate='2026-01-01', @ToDate='2026-01-31', @DataType='Net';
```

### Issue: Application Pool Crashes

**Solution:**
1. Check Event Viewer → Windows Logs → Application
2. Increase application pool memory limit
3. Enable detailed error messages in `Web.config`:

```xml
<system.web>
  <customErrors mode="Off"/>
  <compilation debug="true"/>
</system.web>
```

---

## Performance Optimization

### Database Optimization

```sql
-- Enable query store
ALTER DATABASE POSReporting SET QUERY_STORE = ON;

-- Set recovery model to SIMPLE for non-production
ALTER DATABASE POSReporting SET RECOVERY SIMPLE;

-- Schedule index maintenance
-- Create SQL Agent job to rebuild indexes weekly
```

### Application Optimization

```xml
<!-- Enable output caching -->
<system.web>
  <caching>
    <outputCache enableOutputCache="true"/>
    <outputCacheSettings>
      <outputCacheProfiles>
        <add name="ReportCache" duration="300" varyByParam="*"/>
      </outputCacheProfiles>
    </outputCacheSettings>
  </caching>
</system.web>
```

### IIS Optimization

1. Enable **Static Content Compression**
2. Enable **Dynamic Content Compression**
3. Set **Application Pool Recycling** to off-peak hours
4. Configure **Output Caching** rules

---

## Security Checklist

- [ ] Change default connection string
- [ ] Enable HTTPS/SSL
- [ ] Implement authentication
- [ ] Enable audit logging
- [ ] Set up regular backups
- [ ] Configure firewall rules
- [ ] Use parameterized queries (already implemented)
- [ ] Enable request validation
- [ ] Set secure cookie flags
- [ ] Implement rate limiting

---

## Next Steps

1. ✅ Complete setup and testing
2. 📊 Import production data
3. 👥 Create user accounts
4. 🔒 Configure security
5. 📱 Test mobile responsiveness
6. 🚀 Go live!

---

## Support

For issues or questions:
- **Email**: mangesh.bhattacharya@ontariotechu.net
- **GitHub Issues**: [Create an issue](https://github.com/Mangesh-Bhattacharya/pos-online-report-generation/issues)

---

**Last Updated**: January 2026  
**Version**: 1.0
