// =============================================
// ReportScripts.js - Client-side Real-time Updates
// Version: 1.0
// Author: Mangesh Bhattacharya
// Description: SignalR client and AJAX polling for live data
// =============================================

// Configuration
const realtimeConfig = {
    autoRefreshInterval: 30000, // 30 seconds
    enableSignalR: true,
    fallbackToAjax: true,
    reconnectAttempts: 5,
    reconnectDelay: 3000
};

// SignalR connection
let hubConnection = null;
let reconnectAttempts = 0;
let isConnected = false;
let ajaxFallbackTimer = null;

// Initialize real-time connection
function initializeRealtime() {
    if (realtimeConfig.enableSignalR && typeof $.connection !== 'undefined') {
        initializeSignalR();
    } else if (realtimeConfig.fallbackToAjax) {
        initializeAjaxPolling();
    }
}

// Initialize SignalR connection
function initializeSignalR() {
    try {
        // Create hub proxy
        hubConnection = $.connection.realtimeHub;
        
        // Register client-side methods
        hubConnection.client.updateDepartmentalReport = function(data) {
            updateDepartmentalTable(data);
            updateChart(data);
            showNotification('Report updated', 'success');
        };
        
        hubConnection.client.updateHourlyReport = function(data) {
            updateHourlyChart(data);
        };
        
        hubConnection.client.updateEmployeeReport = function(data) {
            updateEmployeeTable(data);
        };
        
        hubConnection.client.updatePaymentReport = function(data) {
            updatePaymentChart(data);
        };
        
        hubConnection.client.newTransaction = function(transaction) {
            showNotification(`New transaction: $${transaction.Amount.toFixed(2)}`, 'info');
            playNotificationSound();
        };
        
        hubConnection.client.lowStockAlert = function(alert) {
            showNotification(`Low stock alert: ${alert.ProductName} (${alert.CurrentStock} remaining)`, 'warning');
        };
        
        hubConnection.client.reportError = function(error) {
            console.error('Report error:', error);
            showNotification('Error updating report', 'error');
        };
        
        // Connection events
        $.connection.hub.stateChanged(function(state) {
            if (state.newState === $.signalR.connectionState.connected) {
                isConnected = true;
                reconnectAttempts = 0;
                console.log('SignalR connected');
                subscribeToCurrentReport();
                
                // Stop AJAX fallback if running
                if (ajaxFallbackTimer) {
                    clearInterval(ajaxFallbackTimer);
                    ajaxFallbackTimer = null;
                }
            } else if (state.newState === $.signalR.connectionState.disconnected) {
                isConnected = false;
                console.log('SignalR disconnected');
                handleDisconnection();
            }
        });
        
        // Start connection
        $.connection.hub.start()
            .done(function() {
                console.log('SignalR started successfully');
            })
            .fail(function(error) {
                console.error('SignalR connection failed:', error);
                if (realtimeConfig.fallbackToAjax) {
                    initializeAjaxPolling();
                }
            });
            
    } catch (error) {
        console.error('SignalR initialization error:', error);
        if (realtimeConfig.fallbackToAjax) {
            initializeAjaxPolling();
        }
    }
}

// Handle disconnection and reconnection
function handleDisconnection() {
    if (reconnectAttempts < realtimeConfig.reconnectAttempts) {
        reconnectAttempts++;
        console.log(`Reconnection attempt ${reconnectAttempts}...`);
        
        setTimeout(function() {
            $.connection.hub.start()
                .done(function() {
                    console.log('Reconnected successfully');
                })
                .fail(function() {
                    handleDisconnection();
                });
        }, realtimeConfig.reconnectDelay);
    } else {
        console.log('Max reconnection attempts reached, falling back to AJAX');
        if (realtimeConfig.fallbackToAjax) {
            initializeAjaxPolling();
        }
    }
}

// Subscribe to current report updates
function subscribeToCurrentReport() {
    if (!isConnected || !hubConnection) return;
    
    const reportType = getCurrentReportType();
    const fromDate = getFromDate();
    const toDate = getToDate();
    const dataType = getDataType();
    
    hubConnection.server.subscribeToReport(reportType, fromDate, toDate, dataType)
        .done(function() {
            console.log('Subscribed to report updates');
        })
        .fail(function(error) {
            console.error('Subscription failed:', error);
        });
}

// Initialize AJAX polling fallback
function initializeAjaxPolling() {
    console.log('Initializing AJAX polling fallback');
    
    if (ajaxFallbackTimer) {
        clearInterval(ajaxFallbackTimer);
    }
    
    ajaxFallbackTimer = setInterval(function() {
        refreshReportData();
    }, realtimeConfig.autoRefreshInterval);
}

// Refresh report data via AJAX
function refreshReportData() {
    const reportType = getCurrentReportType();
    const fromDate = getFromDate();
    const toDate = getToDate();
    const dataType = getDataType();
    
    $.ajax({
        url: '/api/reports/refresh',
        method: 'POST',
        data: {
            reportType: reportType,
            fromDate: fromDate,
            toDate: toDate,
            dataType: dataType
        },
        success: function(data) {
            updateDepartmentalTable(data);
            updateChart(data);
        },
        error: function(error) {
            console.error('AJAX refresh failed:', error);
        }
    });
}

// Update departmental table with new data
function updateDepartmentalTable(data) {
    const tbody = $('#gvDepartments tbody');
    tbody.empty();
    
    data.forEach(function(item) {
        const row = `
            <tr>
                <td><a href="#" class="department-link" data-id="${item.DepartmentID}">${item.Department}</a></td>
                <td>${formatCurrency(item.Average)}</td>
                <td>${formatCurrency(item.TotalSales)}</td>
                <td>${item.Items}</td>
            </tr>
        `;
        tbody.append(row);
    });
    
    // Reattach click handlers
    attachDepartmentClickHandlers();
}

// Update chart with new data
function updateChart(data) {
    if (typeof salesChart !== 'undefined' && salesChart) {
        salesChart.data.labels = data.map(item => item.Department);
        salesChart.data.datasets[0].data = data.map(item => item.TotalSales);
        salesChart.update();
    }
}

// Render sales chart
let salesChart = null;

function renderSalesChart(data) {
    const ctx = document.getElementById('salesChart');
    if (!ctx) return;
    
    const labels = data.map(item => item.label || item.Department);
    const values = data.map(item => item.value || item.TotalSales);
    
    if (salesChart) {
        salesChart.destroy();
    }
    
    salesChart = new Chart(ctx.getContext('2d'), {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: 'Total Sales ($)',
                data: values,
                backgroundColor: 'rgba(0, 51, 102, 0.7)',
                borderColor: 'rgba(0, 51, 102, 1)',
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            animation: {
                duration: 750
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return '$' + value.toLocaleString();
                        }
                    }
                }
            },
            plugins: {
                title: {
                    display: true,
                    text: 'Sales by Department',
                    font: {
                        size: 18
                    }
                },
                legend: {
                    display: false
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return '$' + context.parsed.y.toLocaleString();
                        }
                    }
                }
            }
        }
    });
}

// Helper functions
function getCurrentReportType() {
    return 'departmental'; // Can be dynamic based on current page
}

function getFromDate() {
    return $('#txtFromDate').val() || new Date().toISOString().split('T')[0];
}

function getToDate() {
    return $('#txtToDate').val() || new Date().toISOString().split('T')[0];
}

function getDataType() {
    return $('#ddlDataType').val() || 'Net';
}

function formatCurrency(value) {
    return '$' + parseFloat(value).toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,');
}

function showNotification(message, type) {
    // Simple notification system
    const notification = $(`
        <div class="alert alert-${type === 'success' ? 'success' : type === 'error' ? 'danger' : type === 'warning' ? 'warning' : 'info'} alert-dismissible fade show notification-toast" role="alert">
            ${message}
            <button type="button" class="close" data-dismiss="alert">
                <span>&times;</span>
            </button>
        </div>
    `);
    
    $('body').append(notification);
    
    setTimeout(function() {
        notification.fadeOut(function() {
            $(this).remove();
        });
    }, 5000);
}

function playNotificationSound() {
    // Optional: Play notification sound
    const audio = new Audio('/Content/sounds/notification.mp3');
    audio.volume = 0.3;
    audio.play().catch(e => console.log('Audio play failed:', e));
}

function attachDepartmentClickHandlers() {
    $('.department-link').off('click').on('click', function(e) {
        e.preventDefault();
        const departmentId = $(this).data('id');
        const fromDate = getFromDate();
        const toDate = getToDate();
        window.location.href = `/DepartmentDetails.aspx?id=${departmentId}&from=${fromDate}&to=${toDate}`;
    });
}

// Auto-refresh toggle
function toggleAutoRefresh(enabled) {
    if (enabled) {
        if (!isConnected && realtimeConfig.fallbackToAjax) {
            initializeAjaxPolling();
        }
    } else {
        if (ajaxFallbackTimer) {
            clearInterval(ajaxFallbackTimer);
            ajaxFallbackTimer = null;
        }
    }
}

// Initialize on document ready
$(document).ready(function() {
    initializeRealtime();
    
    // Add auto-refresh toggle button
    const toggleButton = `
        <button id="btnToggleAutoRefresh" class="btn btn-sm btn-outline-primary" title="Toggle Auto-refresh">
            <i class="fas fa-sync-alt"></i> Auto-refresh: ON
        </button>
    `;
    $('.filter-section .row:first .col-md-12').append(toggleButton);
    
    $('#btnToggleAutoRefresh').on('click', function() {
        const isEnabled = $(this).text().includes('ON');
        toggleAutoRefresh(!isEnabled);
        $(this).html(`<i class="fas fa-sync-alt"></i> Auto-refresh: ${isEnabled ? 'OFF' : 'ON'}`);
        $(this).toggleClass('btn-outline-primary btn-outline-secondary');
    });
});

// Cleanup on page unload
$(window).on('beforeunload', function() {
    if (hubConnection && isConnected) {
        hubConnection.server.unsubscribeFromReport(
            getCurrentReportType(),
            getFromDate(),
            getToDate(),
            getDataType()
        );
    }
    
    if (ajaxFallbackTimer) {
        clearInterval(ajaxFallbackTimer);
    }
});
