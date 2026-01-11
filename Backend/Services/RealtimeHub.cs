// =============================================
// RealtimeHub.cs - SignalR Hub for Real-time Updates
// Version: 1.0
// Author: Mangesh Bhattacharya
// Description: WebSocket hub for pushing live data updates
// =============================================

using System;
using System.Threading.Tasks;
using System.Timers;
using Microsoft.AspNet.SignalR;
using POSReporting.Services;

namespace POSReporting.Hubs
{
    public class RealtimeHub : Hub
    {
        private static Timer _timer;
        private static readonly object _lock = new object();
        private readonly ReportService _reportService;

        public RealtimeHub()
        {
            _reportService = new ReportService();
        }

        // Called when client connects
        public override Task OnConnected()
        {
            StartTimer();
            return base.OnConnected();
        }

        // Called when client disconnects
        public override Task OnDisconnected(bool stopCalled)
        {
            // Stop timer if no clients connected
            if (Context.ConnectionId != null)
            {
                StopTimer();
            }
            return base.OnDisconnected(stopCalled);
        }

        // Client subscribes to specific report updates
        public void SubscribeToReport(string reportType, DateTime fromDate, DateTime toDate, string dataType = "Net")
        {
            string groupName = $"{reportType}_{fromDate:yyyyMMdd}_{toDate:yyyyMMdd}_{dataType}";
            Groups.Add(Context.ConnectionId, groupName);
            
            // Send initial data immediately
            SendReportUpdate(reportType, fromDate, toDate, dataType);
        }

        // Client unsubscribes from report updates
        public void UnsubscribeFromReport(string reportType, DateTime fromDate, DateTime toDate, string dataType = "Net")
        {
            string groupName = $"{reportType}_{fromDate:yyyyMMdd}_{toDate:yyyyMMdd}_{dataType}";
            Groups.Remove(Context.ConnectionId, groupName);
        }

        // Broadcast report update to subscribed clients
        private void SendReportUpdate(string reportType, DateTime fromDate, DateTime toDate, string dataType)
        {
            try
            {
                string groupName = $"{reportType}_{fromDate:yyyyMMdd}_{toDate:yyyyMMdd}_{dataType}";
                
                switch (reportType.ToLower())
                {
                    case "departmental":
                        var deptData = _reportService.GetDepartmentalSales(fromDate, toDate, dataType);
                        Clients.Group(groupName).updateDepartmentalReport(deptData);
                        break;
                        
                    case "hourly":
                        var hourlyData = _reportService.GetHourlySalesTrends(fromDate, toDate);
                        Clients.Group(groupName).updateHourlyReport(hourlyData);
                        break;
                        
                    case "employee":
                        var empData = _reportService.GetEmployeePerformance(fromDate, toDate);
                        Clients.Group(groupName).updateEmployeeReport(empData);
                        break;
                        
                    case "payment":
                        var paymentData = _reportService.GetPaymentMethodAnalysis(fromDate, toDate);
                        Clients.Group(groupName).updatePaymentReport(paymentData);
                        break;
                }
            }
            catch (Exception ex)
            {
                Clients.Caller.reportError(ex.Message);
            }
        }

        // Broadcast new transaction notification
        public void NotifyNewTransaction(int transactionId, decimal amount, string department)
        {
            Clients.All.newTransaction(new
            {
                TransactionId = transactionId,
                Amount = amount,
                Department = department,
                Timestamp = DateTime.Now
            });
        }

        // Broadcast low stock alert
        public void NotifyLowStock(int productId, string productName, int currentStock, int reorderLevel)
        {
            Clients.All.lowStockAlert(new
            {
                ProductId = productId,
                ProductName = productName,
                CurrentStock = currentStock,
                ReorderLevel = reorderLevel,
                Timestamp = DateTime.Now
            });
        }

        // Start auto-refresh timer
        private void StartTimer()
        {
            lock (_lock)
            {
                if (_timer == null)
                {
                    _timer = new Timer(30000); // 30 seconds
                    _timer.Elapsed += OnTimerElapsed;
                    _timer.Start();
                }
            }
        }

        // Stop auto-refresh timer
        private void StopTimer()
        {
            lock (_lock)
            {
                if (_timer != null && GlobalHost.ConnectionManager.GetHubContext<RealtimeHub>().Clients == null)
                {
                    _timer.Stop();
                    _timer.Dispose();
                    _timer = null;
                }
            }
        }

        // Timer elapsed - refresh all active subscriptions
        private void OnTimerElapsed(object sender, ElapsedEventArgs e)
        {
            // This would be called from a background service in production
            // For now, clients will request updates via AJAX polling as fallback
        }

        // Get current connection count
        public int GetConnectionCount()
        {
            return GlobalHost.ConnectionManager.GetHubContext<RealtimeHub>().Clients.All != null ? 1 : 0;
        }

        // Ping for connection health check
        public string Ping()
        {
            return "pong";
        }
    }
}
