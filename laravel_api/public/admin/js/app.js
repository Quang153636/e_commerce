/**
 * E-Commerce Admin Panel
 * Single Page Application - JavaScript
 */

const API_BASE = '/api';
let TOKEN = localStorage.getItem('admin_token') || null;
let ADMIN_USER = null;
let currentPage = 'dashboard';
let currentPageData = {};

// ====== Utilities ======
function $(sel, ctx = document) { return ctx.querySelector(sel); }
function $$(sel, ctx = document) { return [...ctx.querySelectorAll(sel)]; }

function html(strings, ...values) {
    return strings.reduce((result, str, i) => result + str + (values[i] !== undefined ? values[i] : ''), '');
}

function escapeHtml(str) {
    if (!str) return '';
    return String(str).replace(/&/g,'&').replace(/</g,'<').replace(/>/g,'>').replace(/"/g,'"');
}

function formatCurrency(n) {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(n || 0);
}

function formatDate(d) {
    if (!d) return '';
    return new Date(d).toLocaleDateString('vi-VN', { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' });
}

function formatDateShort(d) {
    if (!d) return '';
    return new Date(d).toLocaleDateString('vi-VN', { year: 'numeric', month: '2-digit', day: '2-digit' });
}

function statusClass(status) {
    const map = { 'pending': 'status-pending', 'confirmed': 'status-confirmed', 'shipping': 'status-shipping', 'delivered': 'status-delivered', 'received': 'status-received', 'cancelled': 'status-cancelled' };
    return map[status] || 'status-pending';
}

function statusLabel(status) {
    const map = { 'pending': 'Chờ xác nhận', 'confirmed': 'Đã xác nhận', 'shipping': 'Đang giao', 'delivered': 'Đã giao', 'received': 'Đã nhận', 'cancelled': 'Đã hủy' };
    return map[status] || status;
}

function getInitials(name) {
    if (!name) return '?';
    return name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2);
}

// ====== Toast ======
function showToast(message, type = 'success') {
    const container = $('#toast-container');
    if (!container) return;
    const icons = { success: '✓', error: '✗', info: 'ℹ', warning: '⚠' };
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `<span>${icons[type] || ''}</span> ${escapeHtml(message)}`;
    container.appendChild(toast);
    setTimeout(() => { toast.style.opacity = '0'; setTimeout(() => toast.remove(), 300); }, 3000);
}

// ====== API Call ======
async function apiCall(method, path, body = null) {
    const headers = { 'Accept': 'application/json', 'Content-Type': 'application/json' };
    if (TOKEN) headers['Authorization'] = `Bearer ${TOKEN}`;
    
    const opts = { method, headers };
    if (body && method !== 'GET') opts.body = JSON.stringify(body);
    
    try {
        const res = await fetch(`${API_BASE}${path}`, opts);
        const data = await res.json();
        
        if (!res.ok) {
            const msg = data.message || data.error || `Lỗi ${res.status}`;
            throw new Error(msg);
        }
        return data;
    } catch (err) {
        if (err.message.includes('401') || err.message.includes('Unauthenticated')) {
            logout();
            throw new Error('Phiên đăng nhập hết hạn');
        }
        throw err;
    }
}

// ====== Login ======
async function login(email, password) {
    const data = await apiCall('POST', '/login', { email, password });
    
    if (!data.token) throw new Error('Không nhận được token');
    
    // Check if user is admin
    const user = data.user || data.data || null;
    if (!user || !user.is_admin) {
        throw new Error('Tài khoản không có quyền admin');
    }
    
    TOKEN = data.token;
    ADMIN_USER = user;
    localStorage.setItem('admin_token', TOKEN);
    localStorage.setItem('admin_user', JSON.stringify(ADMIN_USER));
    
    return data;
}

function logout() {
    if (TOKEN) {
        apiCall('POST', '/logout').catch(() => {});
    }
    TOKEN = null;
    ADMIN_USER = null;
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    showLoginPage();
}

// ====== Router ======
function navigate(page, params = {}) {
    currentPage = page;
    currentPageData = params;
    render();
}

// ====== Render ======
function render() {
    const app = $('#app');
    if (!app) return;
    
    if (!TOKEN) {
        showLoginPage();
        return;
    }
    
    app.innerHTML = buildAdminLayout();
    
    // Load user info
    loadUserInfo();
    
    // Render page content
    const content = $('#page-content');
    if (!content) return;
    
    switch (currentPage) {
        case 'dashboard': renderDashboard(content); break;
        case 'orders': renderOrders(content, currentPageData); break;
        case 'order-detail': renderOrderDetail(content, currentPageData); break;
        case 'products': renderProducts(content, currentPageData); break;
        case 'product-form': renderProductForm(content, currentPageData); break;
        case 'categories': renderCategories(content); break;
        case 'users': renderUsers(content, currentPageData); break;
        case 'reviews': renderReviews(content, currentPageData); break;
        default: renderDashboard(content);
    }
    
    // Setup sidebar navigation
    setupSidebar();
}

function buildAdminLayout() {
    return `
    <div class="admin-layout">
        <aside class="sidebar" id="sidebar">
            <div class="sidebar-brand">
                <h2>🛒 Admin</h2>
                <div class="brand-sub">E-Commerce Management</div>
            </div>
            <nav class="sidebar-nav">
                <div class="nav-section">
                    <button class="nav-item ${currentPage === 'dashboard' ? 'active' : ''}" onclick="navigate('dashboard')">
                        <span class="icon">📊</span> Dashboard
                    </button>
                    <button class="nav-item ${currentPage === 'orders' ? 'active' : ''}" onclick="navigate('orders')">
                        <span class="icon">📦</span> Đơn hàng
                    </button>
                    <button class="nav-item ${currentPage === 'products' ? 'active' : ''}" onclick="navigate('products')">
                        <span class="icon">🏷️</span> Sản phẩm
                    </button>
                    <button class="nav-item ${currentPage === 'categories' ? 'active' : ''}" onclick="navigate('categories')">
                        <span class="icon">📂</span> Danh mục
                    </button>
                    <button class="nav-item ${currentPage === 'users' ? 'active' : ''}" onclick="navigate('users')">
                        <span class="icon">👥</span> Người dùng
                    </button>
                    <button class="nav-item ${currentPage === 'reviews' ? 'active' : ''}" onclick="navigate('reviews')">
                        <span class="icon">⭐</span> Đánh giá
                    </button>
                </div>
            </nav>
            <div class="sidebar-footer">
                <div class="user-info">
                    <div class="avatar" id="sidebar-avatar">A</div>
                    <div class="details">
                        <div class="name" id="sidebar-name">Admin</div>
                        <div class="email" id="sidebar-email">admin@email.com</div>
                    </div>
                </div>
                <button class="nav-item" onclick="logout()" style="color:#ef4444;">
                    <span class="icon">🚪</span> Đăng xuất
                </button>
            </div>
        </aside>
        <main class="main-content">
            <header class="top-header">
                <div style="display:flex;align-items:center;gap:12px;">
                    <button class="mobile-toggle" onclick="toggleSidebar()">☰</button>
                    <h1 class="page-title" id="page-title">Dashboard</h1>
                </div>
                <div class="header-actions">
                    <span style="font-size:13px;color:var(--gray-500);" id="header-time"></span>
                </div>
            </header>
            <div class="page-content" id="page-content">
                <div class="loading"><div class="spinner"></div></div>
            </div>
        </main>
    </div>
    <div class="modal-overlay" id="modal-overlay" onclick="if(event.target===this) closeModal()">
        <div class="modal" id="modal-content"></div>
    </div>
    <div class="toast-container" id="toast-container"></div>`;
}

function toggleSidebar() {
    document.getElementById('sidebar').classList.toggle('open');
}

function loadUserInfo() {
    const nameEl = $('#sidebar-name');
    const emailEl = $('#sidebar-email');
    const avatarEl = $('#sidebar-avatar');
    
    if (ADMIN_USER) {
        if (nameEl) nameEl.textContent = ADMIN_USER.name || 'Admin';
        if (emailEl) emailEl.textContent = ADMIN_USER.email || '';
        if (avatarEl) avatarEl.textContent = getInitials(ADMIN_USER.name);
    } else {
        // Fetch user info
        apiCall('GET', '/me').then(user => {
            ADMIN_USER = user;
            localStorage.setItem('admin_user', JSON.stringify(user));
            if (nameEl) nameEl.textContent = user.name || 'Admin';
            if (emailEl) emailEl.textContent = user.email || '';
            if (avatarEl) avatarEl.textContent = getInitials(user.name);
        }).catch(() => {});
    }
}

function setupSidebar() {
    const titleMap = {
        'dashboard': 'Dashboard',
        'orders': 'Quản lý đơn hàng',
        'order-detail': 'Chi tiết đơn hàng',
        'products': 'Quản lý sản phẩm',
        'product-form': currentPageData.id ? 'Sửa sản phẩm' : 'Thêm sản phẩm',
        'categories': 'Quản lý danh mục',
        'users': 'Quản lý người dùng',
        'reviews': 'Quản lý đánh giá'
    };
    const title = $('#page-title');
    if (title) title.textContent = titleMap[currentPage] || 'Dashboard';
    
    // Update clock
    function updateTime() {
        const el = $('#header-time');
        if (el) el.textContent = new Date().toLocaleString('vi-VN');
    }
    updateTime();
    setInterval(updateTime, 60000);
}

// ====== Modal ======
function openModal(html, classes = '') {
    const overlay = $('#modal-overlay');
    const content = $('#modal-content');
    if (!overlay || !content) return;
    content.className = `modal ${classes}`;
    content.innerHTML = html;
    overlay.classList.add('show');
}

function closeModal() {
    const overlay = $('#modal-overlay');
    if (overlay) overlay.classList.remove('show');
}

// ====== Dashboard ======
async function renderDashboard(container) {
    container.innerHTML = '<div class="loading"><div class="spinner"></div></div>';
    
    try {
        const stats = await apiCall('GET', '/admin/stats');
        
        container.innerHTML = `
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-header">
                        <span class="stat-label">Tổng đơn hàng</span>
                        <div class="stat-icon icon-primary">📦</div>
                    </div>
                    <div class="stat-value">${stats.total_orders || 0}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-header">
                        <span class="stat-label">Doanh thu</span>
                        <div class="stat-icon icon-success">💰</div>
                    </div>
                    <div class="stat-value">${formatCurrency(stats.total_revenue || 0)}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-header">
                        <span class="stat-label">Sản phẩm</span>
                        <div class="stat-icon icon-info">🏷️</div>
                    </div>
                    <div class="stat-value">${stats.total_products || 0}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-header">
                        <span class="stat-label">Người dùng</span>
                        <div class="stat-icon icon-warning">👥</div>
                    </div>
                    <div class="stat-value">${stats.total_users || 0}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-header">
                        <span class="stat-label">Đơn chờ xử lý</span>
                        <div class="stat-icon icon-danger">⏳</div>
                    </div>
                    <div class="stat-value">${stats.pending_orders || 0}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-header">
                        <span class="stat-label">Đang giao</span>
                        <div class="stat-icon icon-info">🚚</div>
                    </div>
                    <div class="stat-value">${stats.shipping_orders || 0}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-header">
                        <span class="stat-label">Đã thanh toán</span>
                        <div class="stat-icon icon-success">✅</div>
                    </div>
                    <div class="stat-value">${stats.paid_orders || 0}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-header">
                        <span class="stat-label">Doanh thu hôm nay</span>
                        <div class="stat-icon icon-success">📈</div>
                    </div>
                    <div class="stat-value">${formatCurrency(stats.revenue_today || 0)}</div>
                </div>
            </div>
            
            <div class="charts-grid">
                <div class="card">
                    <div class="card-header">
                        <h3>Đơn hàng gần đây</h3>
                        <button class="btn btn-sm btn-ghost" onclick="navigate('orders')">Xem tất cả →</button>
                    </div>
                    <div class="card-body no-padding">
                        <div class="table-container">
                            <table>
                                <thead>
                                    <tr>
                                        <th>Mã đơn</th>
                                        <th>Khách hàng</th>
                                        <th>Tổng tiền</th>
                                        <th>Trạng thái</th>
                                        <th>Ngày</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${(stats.recent_orders || []).map(o => html`
                                        <tr style="cursor:pointer" onclick="navigate('order-detail', {id: ${o.id}})">
                                            <td><strong>#${escapeHtml(o.code || o.id)}</strong></td>
                                            <td>${escapeHtml(o.user?.name || 'N/A')}</td>
                                            <td>${formatCurrency(o.total)}</td>
                                            <td><span class="status-badge ${statusClass(o.status)}">${statusLabel(o.status)}</span></td>
                                            <td>${formatDateShort(o.created_at)}</td>
                                        </tr>
                                    `).join('')}
                                    ${(!stats.recent_orders || stats.recent_orders.length === 0) ? '<tr><td colspan="5" style="text-align:center;color:var(--gray-500)">Chưa có đơn hàng</td></tr>' : ''}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                
                <div class="card">
                    <div class="card-header">
                        <h3>Sản phẩm bán chạy</h3>
                        <button class="btn btn-sm btn-ghost" onclick="navigate('products')">Xem tất cả →</button>
                    </div>
                    <div class="card-body no-padding">
                        <div class="table-container">
                            <table>
                                <thead>
                                    <tr>
                                        <th>Sản phẩm</th>
                                        <th>Đã bán</th>
                                        <th>Giá</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${(stats.top_products || []).map(p => html`
                                        <tr>
                                            <td>
                                                <div style="display:flex;align-items:center;gap:10px;">
                                                    ${p.image ? `<img src="${escapeHtml(p.image)}" class="product-thumb">` : `<div class="product-thumb-placeholder">📷</div>`}
                                                    <span>${escapeHtml(p.name)}</span>
                                                </div>
                                            </td>
                                            <td><strong>${p.total_sold}</strong></td>
                                            <td>${formatCurrency(p.price)}</td>
                                        </tr>
                                    `).join('')}
                                    ${(!stats.top_products || stats.top_products.length === 0) ? '<tr><td colspan="3" style="text-align:center;color:var(--gray-500)">Chưa có dữ liệu</td></tr>' : ''}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-header">
                    <h3>Thống kê đánh giá</h3>
                </div>
                <div class="card-body">
                    ${stats.review_stats ? html`
                        <div style="display:flex;gap:32px;flex-wrap:wrap;">
                            <div style="text-align:center;">
                                <div style="font-size:48px;font-weight:700;color:var(--primary);">${stats.review_stats.avg_rating || 0}</div>
                                <div style="font-size:14px;color:var(--gray-500);">Điểm trung bình</div>
                                <div class="stars" style="font-size:24px;margin-top:8px;">
                                    ${renderStars(stats.review_stats.avg_rating || 0)}
                                </div>
                            </div>
                            <div style="flex:1;min-width:200px;">
                                <div style="margin-bottom:8px;">
                                    <div style="display:flex;justify-content:space-between;font-size:13px;margin-bottom:4px;">
                                        <span>5 ★</span>
                                        <span>${stats.review_stats.five_stars || 0}</span>
                                    </div>
                                    <div style="height:8px;background:var(--gray-200);border-radius:4px;overflow:hidden;">
                                        <div style="height:100%;width:${stats.review_stats.total_reviews ? ((stats.review_stats.five_stars || 0) / stats.review_stats.total_reviews * 100) : 0}%;background:#f59e0b;border-radius:4px;"></div>
                                    </div>
                                </div>
                                <div style="margin-bottom:8px;">
                                    <div style="display:flex;justify-content:space-between;font-size:13px;margin-bottom:4px;">
                                        <span>4 ★</span>
                                        <span>${stats.review_stats.four_stars || 0}</span>
                                    </div>
                                    <div style="height:8px;background:var(--gray-200);border-radius:4px;overflow:hidden;">
                                        <div style="height:100%;width:${stats.review_stats.total_reviews ? ((stats.review_stats.four_stars || 0) / stats.review_stats.total_reviews * 100) : 0}%;background:#f59e0b;border-radius:4px;"></div>
                                    </div>
                                </div>
                                <div style="margin-bottom:8px;">
                                    <div style="display:flex;justify-content:space-between;font-size:13px;margin-bottom:4px;">
                                        <span>3 ★</span>
                                        <span>${stats.review_stats.three_stars || 0}</span>
                                    </div>
                                    <div style="height:8px;background:var(--gray-200);border-radius:4px;overflow:hidden;">
                                        <div style="height:100%;width:${stats.review_stats.total_reviews ? ((stats.review_stats.three_stars || 0) / stats.review_stats.total_reviews * 100) : 0}%;background:#f59e0b;border-radius:4px;"></div>
                                    </div>
                                </div>
                                <div style="margin-bottom:8px;">
                                    <div style="display:flex;justify-content:space-between;font-size:13px;margin-bottom:4px;">
                                        <span>2 ★</span>
                                        <span>${stats.review_stats.two_stars || 0}</span>
                                    </div>
                                    <div style="height:8px;background:var(--gray-200);border-radius:4px;overflow:hidden;">
                                        <div style="height:100%;width:${stats.review_stats.total_reviews ? ((stats.review_stats.two_stars || 0) / stats.review_stats.total_reviews * 100) : 0}%;background:#f59e0b;border-radius:4px;"></div>
                                    </div>
                                </div>
                                <div>
                                    <div style="display:flex;justify-content:space-between;font-size:13px;margin-bottom:4px;">
                                        <span>1 ★</span>
                                        <span>${stats.review_stats.one_star || 0}</span>
                                    </div>
                                    <div style="height:8px;background:var(--gray-200);border-radius:4px;overflow:hidden;">
                                        <div style="height:100%;width:${stats.review_stats.total_reviews ? ((stats.review_stats.one_star || 0) / stats.review_stats.total_reviews * 100) : 0}%;background:#f59e0b;border-radius:4px;"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    ` : '<p style="color:var(--gray-500)">Chưa có đánh giá</p>'}
                </div>
            </div>
        `;
    } catch (err) {
        container.innerHTML = `<div class="empty-state"><div class="empty-icon">⚠️</div><h3>Lỗi</h3><p>${escapeHtml(err.message)}</p></div>`;
        showToast(err.message, 'error');
    }
}

function renderStars(rating) {
    const full = Math.floor(rating);
    const half = rating % 1 >= 0.5;
    const empty = 5 - full - (half ? 1 : 0);
    return '★'.repeat(full) + (half ? '★' : '') + '<span class="star-empty">' + '★'.repeat(empty) + '</span>';
}

// ====== Orders ======
async function renderOrders(container, params = {}) {
    container.innerHTML = '<div class="loading"><div class="spinner"></div></div>';
    
    try {
        const query = new URLSearchParams();
        if (params.status) query.set('status', params.status);
        if (params.q) query.set('q', params.q);
        if (params.page) query.set('page', params.page);
        
        const data = await apiCall('GET', `/admin/orders?${query.toString()}`);
        const orders = data.data || data || [];
        const pagination = data.links || null;
        
        container.innerHTML = `
            <div class="toolbar">
                <div class="toolbar-left">
                    <div class="search-box">
                        <span class="search-icon">🔍</span>
                        <input type="text" placeholder="Tìm mã đơn, khách hàng..." id="order-search" value="${escapeHtml(params.q || '')}" onkeyup="if(event.key==='Enter') searchOrders()">
                    </div>
                    <select id="order-status-filter" onchange="filterOrders()" style="padding:8px 12px;border:1px solid var(--gray-300);border-radius:8px;font-size:14px;">
                        <option value="">Tất cả trạng thái</option>
                        <option value="pending" ${params.status === 'pending' ? 'selected' : ''}>Chờ xác nhận</option>
                        <option value="confirmed" ${params.status === 'confirmed' ? 'selected' : ''}>Đã xác nhận</option>
                        <option value="shipping" ${params.status === 'shipping' ? 'selected' : ''}>Đang giao</option>
                        <option value="delivered" ${params.status === 'delivered' ? 'selected' : ''}>Đã giao</option>
                        <option value="received" ${params.status === 'received' ? 'selected' : ''}>Đã nhận</option>
                        <option value="cancelled" ${params.status === 'cancelled' ? 'selected' : ''}>Đã hủy</option>
                    </select>
                </div>
            </div>
            
            <div class="card">
                <div class="card-body no-padding">
                    <div class="table-container">
                        <table>
                            <thead>
                                <tr>
                                    <th>Mã đơn</th>
                                    <th>Khách hàng</th>
                                    <th>Sản phẩm</th>
                                    <th>Tổng tiền</th>
                                    <th>Thanh toán</th>
                                    <th>Trạng thái</th>
                                    <th>Ngày</th>
                                    <th>Thao tác</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${orders.map(o => html`
                                    <tr>
                                        <td><strong>#${escapeHtml(o.code || o.id)}</strong></td>
                                        <td>
                                            <div style="display:flex;align-items:center;gap:8px;">
                                                <span class="user-avatar-sm">${getInitials(o.user?.name)}</span>
                                                <span>${escapeHtml(o.user?.name || 'N/A')}</span>
                                            </div>
                                        </td>
                                        <td>${o.items ? o.items.length + ' sản phẩm' : '-'}</td>
                                        <td><strong>${formatCurrency(o.total)}</strong></td>
                                        <td><span class="status-badge ${o.payment_status === 'paid' ? 'status-delivered' : 'status-pending'}">${o.payment_status === 'paid' ? '✅ Đã thanh toán' : '⏳ Chưa TT'}</span></td>
                                        <td><span class="status-badge ${statusClass(o.status)}">${statusLabel(o.status)}</span></td>
                                        <td>${formatDateShort(o.created_at)}</td>
                                        <td>
                                            <div class="actions">
                                                <button class="btn btn-sm btn-info" onclick="navigate('order-detail', {id: ${o.id}})">Chi tiết</button>
                                                <button class="btn btn-sm btn-primary" onclick="showUpdateOrderStatus(${o.id}, '${o.status}')">Cập nhật</button>
                                            </div>
                                        </td>
                                    </tr>
                                `).join('')}
                                ${orders.length === 0 ? '<tr><td colspan="8" style="text-align:center;padding:40px;color:var(--gray-500)">Không tìm thấy đơn hàng</td></tr>' : ''}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            
            ${pagination ? renderPagination(pagination, 'orders') : ''}
        `;
    } catch (err) {
        container.innerHTML = `<div class="empty-state"><div class="empty-icon">⚠️</div><h3>Lỗi</h3><p>${escapeHtml(err.message)}</p></div>`;
        showToast(err.message, 'error');
    }
}

function searchOrders() {
    const q = $('#order-search')?.value || '';
    const status = $('#order-status-filter')?.value || '';
    navigate('orders', { q, status: status || undefined });
}

function filterOrders() {
    const status = $('#order-status-filter')?.value || '';
    const q = $('#order-search')?.value || '';
    navigate('orders', { q, status: status || undefined });
}

async function showUpdateOrderStatus(orderId, currentStatus) {
    const statuses = ['pending', 'confirmed', 'shipping', 'delivered', 'received', 'cancelled'];
    const options = statuses.filter(s => s !== currentStatus).map(s => 
        `<option value="${s}">${statusLabel(s)}</option>`
    ).join('');
    
    openModal(`
        <div class="modal-header">
            <h3>Cập nhật trạng thái đơn hàng #${orderId}</h3>
            <button class="modal-close" onclick="closeModal()">×</button>
        </div>
        <div class="modal-body">
            <div class="form-group">
                <label>Trạng thái mới</label>
                <select id="new-order-status">${options}</select>
            </div>
            <div class="form-group">
                <label>Ghi chú</label>
                <textarea id="order-status-note" placeholder="Ghi chú (không bắt buộc)"></textarea>
            </div>
        </div>
        <div class="modal-footer">
            <button class="btn btn-ghost" onclick="closeModal()">Hủy</button>
            <button class="btn btn-primary" onclick="updateOrderStatus(${orderId})">Cập nhật</button>
        </div>
    `, 'modal-sm');
}

async function updateOrderStatus(orderId) {
    const status = $('#new-order-status')?.value;
    const note = $('#order-status-note')?.value || '';
    
    if (!status) return showToast('Vui lòng chọn trạng thái', 'error');
    
    try {
        await apiCall('POST', `/admin/orders/${orderId}/status`, { status, note });
        showToast('Cập nhật trạng thái thành công');
        closeModal();
        navigate('order-detail', { id: orderId });
    } catch (err) {
        showToast(err.message, 'error');
    }
}

// ====== Order Detail ======
async function renderOrderDetail(container, params) {
    container.innerHTML = '<div class="loading"><div class="spinner"></div></div>';
    
    try {
        const order = await apiCall('GET', `/admin/orders/${params.id}`);
        
        container.innerHTML = `
            <button class="btn btn-ghost" onclick="navigate('orders')" style="margin-bottom:16px;">← Quay lại</button>
            
            <div class="card" style="margin-bottom:24px;">
                <div class="card-header">
                    <h3>Đơn hàng #${escapeHtml(order.code || order.id)}</h3>
                    <div style="display:flex;gap:8px;">
                        <span class="status-badge ${statusClass(order.status)}">${statusLabel(order.status)}</span>
                        <span class="status-badge ${order.payment_status === 'paid' ? 'status-delivered' : 'status-pending'}">${order.payment_status === 'paid' ? 'Đã thanh toán' : 'Chưa thanh toán'}</span>
                    </div>
                </div>
                <div class="card-body">
                    <div class="detail-grid">
                        <div class="detail-item">
                            <div class="label">Khách hàng</div>
                            <div class="value">${escapeHtml(order.user?.name || 'N/A')}</div>
                        </div>
                        <div class="detail-item">
                            <div class="label">Email</div>
                            <div class="value">${escapeHtml(order.user?.email || 'N/A')}</div>
                        </div>
                        <div class="detail-item">
                            <div class="label">Số điện thoại</div>
                            <div class="value">${escapeHtml(order.shipping_phone || order.phone || 'N/A')}</div>
                        </div>
                        <div class="detail-item">
                            <div class="label">Địa chỉ</div>
                            <div class="value">${escapeHtml(order.shipping_address || order.address || 'N/A')}</div>
                        </div>
                        <div class="detail-item">
                            <div class="label">Phương thức thanh toán</div>
                            <div class="value">${order.payment_method === 'cod' ? 'Thanh toán khi nhận hàng' : escapeHtml(order.payment_method || 'N/A')}</div>
                        </div>
                        <div class="detail-item">
                            <div class="label">Phí vận chuyển</div>
                            <div class="value">${formatCurrency(order.shipping_fee || 0)}</div>
                        </div>
                        <div class="detail-item">
                            <div class="label">Tổng tiền</div>
                            <div class="value" style="font-size:20px;color:var(--primary);">${formatCurrency(order.total)}</div>
                        </div>
                        <div class="detail-item">
                            <div class="label">Ngày đặt</div>
                            <div class="value">${formatDate(order.created_at)}</div>
                        </div>
                    </div>
                    
                    <div style="margin-top:24px;display:flex;gap:8px;flex-wrap:wrap;">
                        <button class="btn btn-primary" onclick="showUpdateOrderStatus(${order.id}, '${order.status}')">Cập nhật trạng thái</button>
                        ${order.status === 'shipping' ? `
                        <button class="btn btn-info" onclick="showUpdateLocation(${order.id})">Cập nhật vị trí</button>
                        ` : ''}
                    </div>
                </div>
            </div>
            
            <div class="card" style="margin-bottom:24px;">
                <div class="card-header">
                    <h3>Sản phẩm trong đơn (${(order.items || []).length})</h3>
                </div>
                <div class="card-body no-padding">
                    <div class="table-container">
                        <table>
                            <thead>
                                <tr>
                                    <th>Sản phẩm</th>
                                    <th>Biến thể</th>
                                    <th>SL</th>
                                    <th>Đơn giá</th>
                                    <th>Thành tiền</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${(order.items || []).map(item => html`
                                    <tr>
                                        <td>
                                            <div style="display:flex;align-items:center;gap:10px;">
                                                ${item.product?.images?.[0] ? `<img src="${escapeHtml(item.product.images[0])}" class="product-thumb">` : `<div class="product-thumb-placeholder">📷</div>`}
                                                <span>${escapeHtml(item.product?.name || item.product_name || 'Sản phẩm')}</span>
                                            </div>
                                        </td>
                                        <td>${escapeHtml(item.variant_text || item.variant_name || '-')}</td>
                                        <td>${item.quantity}</td>
                                        <td>${formatCurrency(item.price)}</td>
                                        <td><strong>${formatCurrency(item.price * item.quantity)}</strong></td>
                                    </tr>
                                `).join('')}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            
            ${order.status_histories && order.status_histories.length > 0 ? `
            <div class="card" style="margin-bottom:24px;">
                <div class="card-header">
                    <h3>Lịch sử trạng thái</h3>
                </div>
                <div class="card-body">
                    <div class="timeline">
                        ${order.status_histories.map(h => html`
                            <div class="timeline-item">
                                <div class="time">${formatDate(h.created_at)}</div>
                                <div class="text"><span class="status-badge ${statusClass(h.status)}">${statusLabel(h.status)}</span></div>
                                ${h.note ? `<div class="note">${escapeHtml(h.note)}</div>` : ''}
                            </div>
                        `).join('')}
                    </div>
                </div>
            </div>
            ` : ''}
        `;
    } catch (err) {
        container.innerHTML = `<div class="empty-state"><div class="empty-icon">⚠️</div><h3>Lỗi</h3><p>${escapeHtml(err.message)}</p></div>`;
        showToast(err.message, 'error');
    }
}

function showUpdateLocation(orderId) {
    openModal(`
        <div class="modal-header">
            <h3>Cập nhật vị trí giao hàng</h3>
            <button class="modal-close" onclick="closeModal()">×</button>
        </div>
        <div class="modal-body">
            <div class="form-group">
                <label>Vĩ độ (Latitude)</label>
                <input type="number" step="any" id="location-lat" placeholder="VD: 10.762622">
            </div>
            <div class="form-group">
                <label>Kinh độ (Longitude)</label>
                <input type="number" step="any" id="location-lng" placeholder="VD: 106.660172">
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label>Tên shipper</label>
                    <input type="text" id="shipper-name" placeholder="Tên người giao">
                </div>
                <div class="form-group">
                    <label>SĐT shipper</label>
                    <input type="text" id="shipper-phone" placeholder="Số điện thoại">
                </div>
            </div>
        </div>
        <div class="modal-footer">
            <button class="btn btn-ghost" onclick="closeModal()">Hủy</button>
            <button class="btn btn-primary" onclick="updateLocation(${orderId})">Cập nhật</button>
        </div>
    `, 'modal-sm');
}

async function updateLocation(orderId) {
    const lat = parseFloat($('#location-lat')?.value);
    const lng = parseFloat($('#location-lng')?.value);
    
    if (!lat || !lng) return showToast('Vui lòng nhập tọa độ', 'error');
    
    try {
        await apiCall('POST', `/admin/orders/${orderId}/location`, {
            lat, lng,
            shipper_name: $('#shipper-name')?.value || '',
            shipper_phone: $('#shipper-phone')?.value || ''
        });
        showToast('Cập nhật vị trí thành công');
        closeModal();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

// ====== Products ======
async function renderProducts(container, params = {}) {
    container.innerHTML = '<div class="loading"><div class="spinner"></div></div>';
    
    try {
        const query = new URLSearchParams();
        if (params.q) query.set('q', params.q);
        if (params.category_id) query.set('category_id', params.category_id);
        if (params.page) query.set('page', params.page);
        
        const data = await apiCall('GET', `/admin/products?${query.toString()}`);
        const products = data.data || data || [];
        const pagination = data.links || null;
        
        // Fetch categories for filter
        const categories = await apiCall('GET', '/admin/categories');
        
        container.innerHTML = `
            <div class="toolbar">
                <div class="toolbar-left">
                    <div class="search-box">
                        <span class="search-icon">🔍</span>
                        <input type="text" placeholder="Tìm sản phẩm..." id="product-search" value="${escapeHtml(params.q || '')}" onkeyup="if(event.key==='Enter') searchProducts()">
                    </div>
                    <select id="product-category-filter" onchange="filterProducts()" style="padding:8px 12px;border:1px solid var(--gray-300);border-radius:8px;font-size:14px;">
                        <option value="">Tất cả danh mục</option>
                        ${(Array.isArray(categories) ? categories : []).map(c => 
                            `<option value="${c.id}" ${params.category_id == c.id ? 'selected' : ''}>${escapeHtml(c.name)}</option>`
                        ).join('')}
                    </select>
                </div>
                <div class="toolbar-right">
                    <button class="btn btn-primary" onclick="navigate('product-form')">+ Thêm sản phẩm</button>
                </div>
            </div>
            
            <div class="card">
                <div class="card-body no-padding">
                    <div class="table-container">
                        <table>
                            <thead>
                                <tr>
                                    <th>Sản phẩm</th>
                                    <th>Danh mục</th>
                                    <th>Giá</th>
                                    <th>Giá KM</th>
                                    <th>Kho</th>
                                    <th>Trạng thái</th>
                                    <th>Ngày</th>
                                    <th>Thao tác</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${products.map(p => html`
                                    <tr>
                                        <td>
                                            <div style="display:flex;align-items:center;gap:10px;">
                                                ${p.images && p.images[0] ? `<img src="${escapeHtml(p.images[0])}" class="product-thumb">` : `<div class="product-thumb-placeholder">📷</div>`}
                                                <div>
                                                    <div style="font-weight:500;">${escapeHtml(p.name)}</div>
                                                    ${p.variants && p.variants.length > 0 ? `<div style="font-size:12px;color:var(--gray-500);">${p.variants.length} biến thể</div>` : ''}
                                                </div>
                                            </div>
                                        </td>
                                        <td>${escapeHtml(p.category?.name || 'N/A')}</td>
                                        <td>${formatCurrency(p.price)}</td>
                                        <td>${p.sale_price ? formatCurrency(p.sale_price) : '-'}</td>
                                        <td><span style="font-weight:${p.stock < 10 ? '600;color:var(--danger)' : '500'}">${p.stock}</span></td>
                                        <td><span class="status-badge ${p.is_active ? 'status-delivered' : 'status-cancelled'}">${p.is_active ? 'Hiển thị' : 'Ẩn'}</span></td>
                                        <td>${formatDateShort(p.created_at)}</td>
                                        <td>
                                            <div class="actions">
                                                <button class="btn btn-sm btn-info" onclick="navigate('product-form', {id: ${p.id}})">Sửa</button>
                                                <button class="btn btn-sm btn-danger" onclick="confirmDeleteProduct(${p.id}, '${escapeHtml(p.name).replace(/'/g, "\\'")}')">Xóa</button>
                                            </div>
                                        </td>
                                    </tr>
                                `).join('')}
                                ${products.length === 0 ? '<tr><td colspan="8" style="text-align:center;padding:40px;color:var(--gray-500)">Không tìm thấy sản phẩm</td></tr>' : ''}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            
            ${pagination ? renderPagination(pagination, 'products') : ''}
        `;
    } catch (err) {
        container.innerHTML = `<div class="empty-state"><div class="empty-icon">⚠️</div><h3>Lỗi</h3><p>${escapeHtml(err.message)}</p></div>`;
        showToast(err.message, 'error');
    }
}

function searchProducts() {
    const q = $('#product-search')?.value || '';
    const category_id = $('#product-category-filter')?.value || '';
    navigate('products', { q, category_id: category_id || undefined });
}

function filterProducts() {
    const category_id = $('#product-category-filter')?.value || '';
    const q = $('#product-search')?.value || '';
    navigate('products', { q, category_id: category_id || undefined });
}

function confirmDeleteProduct(id, name) {
    openModal(`
        <div class="modal-header">
            <h3>Xác nhận xóa</h3>
            <button class="modal-close" onclick="closeModal()">×</button>
        </div>
        <div class="modal-body">
            <p>Bạn có chắc chắn muốn xóa sản phẩm <strong>${escapeHtml(name)}</strong>?</p>
            <p style="color:var(--gray-500);font-size:13px;margin-top:8px;">Hành động này không thể hoàn tác.</p>
        </div>
        <div class="modal-footer">
            <button class="btn btn-ghost" onclick="closeModal()">Hủy</button>
            <button class="btn btn-danger" onclick="deleteProduct(${id})">Xóa</button>
        </div>
    `, 'modal-sm');
}

async function deleteProduct(id) {
    try {
        await apiCall('DELETE', `/admin/products/${id}`);
        showToast('Xóa sản phẩm thành công');
        closeModal();
        navigate('products');
    } catch (err) {
        showToast(err.message, 'error');
    }
}

// ====== Product Form ======
async function renderProductForm(container, params = {}) {
    container.innerHTML = '<div class="loading"><div class="spinner"></div></div>';
    
    try {
        const categories = await apiCall('GET', '/admin/categories');
        let product = null;
        
        if (params.id) {
            const res = await apiCall('GET', `/admin/products?q=&per_page=100`);
            const products = res.data || res || [];
            product = Array.isArray(products) ? products.find(p => p.id == params.id) : null;
        }
        
        container.innerHTML = `
            <button class="btn btn-ghost" onclick="navigate('products')" style="margin-bottom:16px;">← Quay lại</button>
            
            <div class="card">
                <div class="card-header">
                    <h3>${product ? 'Sửa sản phẩm' : 'Thêm sản phẩm mới'}</h3>
                </div>
                <div class="card-body">
                    <form id="product-form" onsubmit="saveProduct(event)">
                        <div class="form-group">
                            <label>Tên sản phẩm</label>
                            <input type="text" name="name" required value="${escapeHtml(product?.name || '')}" placeholder="Nhập tên sản phẩm">
                        </div>
                        
                        <div class="form-row">
                            <div class="form-group">
                                <label>Danh mục</label>
                                <select name="category_id" required>
                                    <option value="">Chọn danh mục</option>
                                    ${(Array.isArray(categories) ? categories : []).map(c => 
                                        `<option value="${c.id}" ${product?.category_id == c.id ? 'selected' : ''}>${escapeHtml(c.name)}</option>`
                                    ).join('')}
                                </select>
                            </div>
                            <div class="form-group">
                                <label>Trạng thái</label>
                                <select name="is_active">
                                    <option value="1" ${product?.is_active !== false ? 'selected' : ''}>Hiển thị</option>
                                    <option value="0" ${product?.is_active === false ? 'selected' : ''}>Ẩn</option>
                                </select>
                            </div>
                        </div>
                        
                        <div class="form-group">
                            <label>Mô tả</label>
                            <textarea name="description" placeholder="Mô tả sản phẩm">${escapeHtml(product?.description || '')}</textarea>
                        </div>
                        
                        <div class="form-row">
                            <div class="form-group">
                                <label>Giá (VND)</label>
                                <input type="number" name="price" required min="0" value="${product?.price || 0}" placeholder="VD: 100000">
                            </div>
                            <div class="form-group">
                                <label>Giá khuyến mãi (VND)</label>
                                <input type="number" name="sale_price" min="0" value="${product?.sale_price || ''}" placeholder="VD: 80000">
                            </div>
                        </div>
                        
                        <div class="form-row">
                            <div class="form-group">
                                <label>Số lượng tồn kho</label>
                                <input type="number" name="stock" required min="0" value="${product?.stock || 0}" placeholder="0">
                                <div class="help-text">Nếu có biến thể, tồn kho sẽ tự động tính từ biến thể</div>
                            </div>
                            <div class="form-group">
                                <label>Hình ảnh (URL, mỗi URL trên một dòng)</label>
                                <textarea name="images_text" placeholder="https://example.com/image1.jpg&#10;https://example.com/image2.jpg">${(product?.images || []).join('\n')}</textarea>
                            </div>
                        </div>
                        
                        <div class="form-group">
                            <label>
                                <input type="checkbox" id="has-variants" ${product?.variant_types && product.variant_types.length > 0 ? 'checked' : ''} onchange="toggleVariants()">
                                Sản phẩm có biến thể (size, màu sắc...)
                            </label>
                        </div>
                        
                        <div id="variants-section" style="${product?.variant_types && product.variant_types.length > 0 ? 'display:block' : 'display:none'}">
                            <div class="variant-builder">
                                <h4 style="margin-bottom:12px;font-size:14px;color:var(--gray-600);">Loại biến thể</h4>
                                <div id="variant-types-container">
                                    ${renderVariantTypes(product?.variant_types || [])}
                                </div>
                                <button type="button" class="btn btn-sm btn-ghost" onclick="addVariantType()" style="margin-top:8px;">+ Thêm loại biến thể</button>
                            </div>
                            
                            <div class="variant-builder" style="margin-top:12px;">
                                <h4 style="margin-bottom:12px;font-size:14px;color:var(--gray-600);">Biến thể chi tiết</h4>
                                <div id="variants-container">
                                    ${renderVariants(product?.variants || [], product?.variant_types || [])}
                                </div>
                                <p style="font-size:12px;color:var(--gray-500);margin-top:8px;">Các biến thể sẽ được tự động tạo từ loại biến thể ở trên. Bạn có thể điều chỉnh giá và tồn kho cho từng biến thể.</p>
                            </div>
                        </div>
                        
                        <div style="margin-top:24px;display:flex;gap:12px;justify-content:flex-end;">
                            <button type="button" class="btn btn-ghost" onclick="navigate('products')">Hủy</button>
                            <button type="submit" class="btn btn-primary btn-lg">${product ? 'Cập nhật' : 'Tạo mới'}</button>
                        </div>
                    </form>
                </div>
            </div>
        `;
        
        if (product?.variant_types && product.variant_types.length > 0) {
            generateVariants();
        }
    } catch (err) {
        container.innerHTML = `<div class="empty-state"><div class="empty-icon">⚠️</div><h3>Lỗi</h3><p>${escapeHtml(err.message)}</p></div>`;
        showToast(err.message, 'error');
    }
}

let variantTypeCount = 0;

function renderVariantTypes(types) {
    if (!types || types.length === 0) {
        return '';
    }
    return types.map((t, i) => html`
        <div class="variant-type-row" data-index="${i}">
            <input type="text" class="variant-type-name" placeholder="VD: Màu sắc" value="${escapeHtml(t.name)}">
            <input type="text" class="variant-type-options" placeholder="VD: Đỏ, Xanh, Trắng" value="${(t.options || []).join(', ')}">
            <button type="button" class="btn btn-sm btn-danger" onclick="this.closest('.variant-type-row').remove(); generateVariants();">×</button>
        </div>
    `).join('');
}

function addVariantType() {
    const container = $('#variant-types-container');
    if (!container) return;
    const div = document.createElement('div');
    div.className = 'variant-type-row';
    div.innerHTML = `
        <input type="text" class="variant-type-name" placeholder="VD: Màu sắc">
        <input type="text" class="variant-type-options" placeholder="VD: Đỏ, Xanh, Trắng">
        <button type="button" class="btn btn-sm btn-danger" onclick="this.closest('.variant-type-row').remove(); generateVariants();">×</button>
    `;
    container.appendChild(div);
    generateVariants();
}

function getVariantTypes() {
    const rows = $$('.variant-type-row');
    return rows.map(row => ({
        name: row.querySelector('.variant-type-name')?.value?.trim() || '',
        options: (row.querySelector('.variant-type-options')?.value || '').split(',').map(s => s.trim()).filter(Boolean)
    })).filter(t => t.name && t.options.length > 0);
}

function generateVariants() {
    const container = $('#variants-container');
    if (!container) return;
    
    const types = getVariantTypes();
    if (types.length === 0) {
        container.innerHTML = '<p style="color:var(--gray-500);font-size:13px;">Thêm loại biến thể để tạo biến thể tự động</p>';
        return;
    }
    
    // Generate combinations
    function combine(arrays, prefix = []) {
        if (arrays.length === 0) return [prefix];
        const [first, ...rest] = arrays;
        const result = [];
        for (const item of first) {
            result.push(...combine(rest, [...prefix, item]));
        }
        return result;
    }
    
    const allOptions = types.map(t => t.options);
    const combinations = combine(allOptions);
    
    let html = '<table style="width:100%;"><thead><tr>';
    types.forEach(t => {
        html += `<th style="font-size:12px;font-weight:600;color:var(--gray-500);padding:8px;text-align:left;">${escapeHtml(t.name)}</th>`;
    });
    html += '<th style="font-size:12px;font-weight:600;color:var(--gray-500);padding:8px;text-align:left;">Giá (để trống = giá mặc định)</th>';
    html += '<th style="font-size:12px;font-weight:600;color:var(--gray-500);padding:8px;text-align:left;">Tồn kho</th>';
    html += '<th style="font-size:12px;font-weight:600;color:var(--gray-500);padding:8px;text-align:left;">SKU</th>';
    html += '</tr></thead><tbody>';
    
    combinations.forEach((combo, idx) => {
        html += '<tr>';
        combo.forEach(val => {
            html += `<td style="padding:8px;border-bottom:1px solid var(--gray-100);font-size:13px;">${escapeHtml(val)}</td>`;
        });
        html += `<td style="padding:8px;border-bottom:1px solid var(--gray-100);">
            <input type="number" class="variant-price" min="0" placeholder="Để trống" style="width:120px;padding:6px 8px;border:1px solid var(--gray-300);border-radius:4px;font-size:13px;">
        </td>`;
        html += `<td style="padding:8px;border-bottom:1px solid var(--gray-100);">
            <input type="number" class="variant-stock" min="0" value="0" style="width:80px;padding:6px 8px;border:1px solid var(--gray-300);border-radius:4px;font-size:13px;">
        </td>`;
        html += `<td style="padding:8px;border-bottom:1px solid var(--gray-100);">
            <input type="text" class="variant-sku" placeholder="SKU" style="width:100px;padding:6px 8px;border:1px solid var(--gray-300);border-radius:4px;font-size:13px;">
            <input type="hidden" class="variant-attributes" value='${JSON.stringify(
                combo.reduce((acc, val, i) => ({ ...acc, [types[i].name]: val }), {})
            )}'>
        </td>`;
        html += '</tr>';
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

function toggleVariants() {
    const section = $('#variants-section');
    const checkbox = $('#has-variants');
    if (section && checkbox) {
        section.style.display = checkbox.checked ? 'block' : 'none';
        if (checkbox.checked) generateVariants();
    }
}

async function saveProduct(event) {
    event.preventDefault();
    const form = event.target;
    const isEdit = currentPageData.id ? true : false;
    
    const imagesText = form.images_text?.value || '';
    const images = imagesText.split('\n').map(s => s.trim()).filter(Boolean);
    
    const data = {
        category_id: parseInt(form.category_id.value),
        name: form.name.value,
        description: form.description?.value || '',
        price: parseFloat(form.price.value) || 0,
        sale_price: form.sale_price?.value ? parseFloat(form.sale_price.value) : null,
        stock: parseInt(form.stock.value) || 0,
        images: images,
        is_active: form.is_active?.value === '1',
    };
    
    const hasVariants = $('#has-variants')?.checked;
    if (hasVariants) {
        const types = getVariantTypes();
        data.variant_types = types;
        
        const variantRows = $$('#variants-container tbody tr');
        data.variants = variantRows.map(row => {
            const attrsInput = row.querySelector('.variant-attributes');
            const priceInput = row.querySelector('.variant-price');
            const stockInput = row.querySelector('.variant-stock');
            const skuInput = row.querySelector('.variant-sku');
            return {
                attributes: JSON.parse(attrsInput?.value || '{}'),
                price: priceInput?.value ? parseFloat(priceInput.value) : null,
                stock: parseInt(stockInput?.value) || 0,
                sku: skuInput?.value || null,
            };
        });
    }
    
    const saveBtn = form.querySelector('button[type="submit"]');
    saveBtn.disabled = true;
    saveBtn.textContent = 'Đang lưu...';
    
    try {
        if (isEdit) {
            await apiCall('PUT', `/admin/products/${currentPageData.id}`, data);
            showToast('Cập nhật sản phẩm thành công');
        } else {
            await apiCall('POST', '/admin/products', data);
            showToast('Thêm sản phẩm thành công');
        }
        navigate('products');
    } catch (err) {
        showToast(err.message, 'error');
        saveBtn.disabled = false;
        saveBtn.textContent = isEdit ? 'Cập nhật' : 'Tạo mới';
    }
}

function renderVariants(variants, types) {
    if (!variants || variants.length === 0) {
        return '<p style="color:var(--gray-500);font-size:13px;">Chưa có biến thể</p>';
    }
    
    let html = '<table style="width:100%;"><thead><tr>';
    types.forEach(t => {
        html += `<th style="font-size:12px;padding:8px;text-align:left;">${escapeHtml(t.name)}</th>`;
    });
    html += '<th style="font-size:12px;padding:8px;text-align:left;">Giá</th>';
    html += '<th style="font-size:12px;padding:8px;text-align:left;">Tồn kho</th>';
    html += '<th style="font-size:12px;padding:8px;text-align:left;">SKU</th>';
    html += '</tr></thead><tbody>';
    
    variants.forEach(v => {
        const attrs = v.attributes || {};
        html += '<tr>';
        types.forEach(t => {
            html += `<td style="padding:8px;border-bottom:1px solid var(--gray-100);font-size:13px;">${escapeHtml(attrs[t.name] || '')}</td>`;
        });
        html += `<td style="padding:8px;border-bottom:1px solid var(--gray-100);">${v.price ? formatCurrency(v.price) : '-'}</td>`;
        html += `<td style="padding:8px;border-bottom:1px solid var(--gray-100);">${v.stock}</td>`;
        html += `<td style="padding:8px;border-bottom:1px solid var(--gray-100);">${escapeHtml(v.sku || '-')}</td>`;
        html += '</tr>';
    });
    
    html += '</tbody></table>';
    return html;
}

// ====== Categories ======
async function renderCategories(container) {
    container.innerHTML = '<div class="loading"><div class="spinner"></div></div>';
    
    try {
        const categories = await apiCall('GET', '/admin/categories');
        const cats = Array.isArray(categories) ? categories : [];
        
        container.innerHTML = `
            <div class="toolbar">
                <div class="toolbar-right">
                    <button class="btn btn-primary" onclick="showAddCategory()">+ Thêm danh mục</button>
                </div>
            </div>
            
            <div class="card">
                <div class="card-body no-padding">
                    <div class="table-container">
                        <table>
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Tên danh mục</th>
                                    <th>Slug</th>
                                    <th>Icon</th>
                                    <th>Số sản phẩm</th>
                                    <th>Thao tác</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${cats.map(c => html`
                                    <tr>
                                        <td>${c.id}</td>
                                        <td><strong>${escapeHtml(c.name)}</strong></td>
                                        <td>${escapeHtml(c.slug)}</td>
                                        <td>${c.icon || '-'}</td>
                                        <td>${c.products_count || 0}</td>
                                        <td>
                                            <div class="actions">
                                                <button class="btn btn-sm btn-info" onclick="showEditCategory(${c.id}, '${escapeHtml(c.name).replace(/'/g, "\\'")}', '${escapeHtml(c.icon || '').replace(/'/g, "\\'")}')">Sửa</button>
                                                <button class="btn btn-sm btn-danger" onclick="confirmDeleteCategory(${c.id}, '${escapeHtml(c.name).replace(/'/g, "\\'")}')">Xóa</button>
                                            </div>
                                        </td>
                                    </tr>
                                `).join('')}
                                ${cats.length === 0 ? '<tr><td colspan="6" style="text-align:center;padding:40px;color:var(--gray-500)">Chưa có danh mục</td></tr>' : ''}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        `;
    } catch (err) {
        container.innerHTML = `<div class="empty-state"><div class="empty-icon">⚠️</div><h3>Lỗi</h3><p>${escapeHtml(err.message)}</p></div>`;
        showToast(err.message, 'error');
    }
}

function showAddCategory() {
    openModal(`
        <div class="modal-header">
            <h3>Thêm danh mục</h3>
            <button class="modal-close" onclick="closeModal()">×</button>
        </div>
        <div class="modal-body">
            <div class="form-group">
                <label>Tên danh mục</label>
                <input type="text" id="category-name" placeholder="VD: Điện thoại">
            </div>
            <div class="form-group">
                <label>Icon (emoji hoặc tên icon)</label>
                <input type="text" id="category-icon" placeholder="VD: 📱" maxlength="50">
            </div>
        </div>
        <div class="modal-footer">
            <button class="btn btn-ghost" onclick="closeModal()">Hủy</button>
            <button class="btn btn-primary" onclick="saveCategory()">Thêm</button>
        </div>
    `, 'modal-sm');
}

function showEditCategory(id, name, icon) {
    openModal(`
        <div class="modal-header">
            <h3>Sửa danh mục</h3>
            <button class="modal-close" onclick="closeModal()">×</button>
        </div>
        <div class="modal-body">
            <div class="form-group">
                <label>Tên danh mục</label>
                <input type="text" id="category-name" value="${escapeHtml(name)}">
            </div>
            <div class="form-group">
                <label>Icon</label>
                <input type="text" id="category-icon" value="${escapeHtml(icon)}" maxlength="50">
            </div>
        </div>
        <div class="modal-footer">
            <button class="btn btn-ghost" onclick="closeModal()">Hủy</button>
            <button class="btn btn-primary" onclick="saveCategory(${id})">Cập nhật</button>
        </div>
    `, 'modal-sm');
}

async function saveCategory(id = null) {
    const name = $('#category-name')?.value?.trim();
    if (!name) return showToast('Vui lòng nhập tên danh mục', 'error');
    
    const icon = $('#category-icon')?.value?.trim() || '';
    
    try {
        if (id) {
            await apiCall('PUT', `/admin/categories/${id}`, { name, icon });
            showToast('Cập nhật danh mục thành công');
        } else {
            await apiCall('POST', '/admin/categories', { name, icon });
            showToast('Thêm danh mục thành công');
        }
        closeModal();
        navigate('categories');
    } catch (err) {
        showToast(err.message, 'error');
    }
}

function confirmDeleteCategory(id, name) {
    openModal(`
        <div class="modal-header">
            <h3>Xác nhận xóa</h3>
            <button class="modal-close" onclick="closeModal()">×</button>
        </div>
        <div class="modal-body">
            <p>Bạn có chắc chắn muốn xóa danh mục <strong>${escapeHtml(name)}</strong>?</p>
            <p style="color:var(--gray-500);font-size:13px;margin-top:8px;">Các sản phẩm trong danh mục này sẽ không bị xóa.</p>
        </div>
        <div class="modal-footer">
            <button class="btn btn-ghost" onclick="closeModal()">Hủy</button>
            <button class="btn btn-danger" onclick="deleteCategory(${id})">Xóa</button>
        </div>
    `, 'modal-sm');
}

async function deleteCategory(id) {
    try {
        await apiCall('DELETE', `/admin/categories/${id}`);
        showToast('Xóa danh mục thành công');
        closeModal();
        navigate('categories');
    } catch (err) {
        showToast(err.message, 'error');
    }
}

// ====== Users ======
async function renderUsers(container, params = {}) {
    container.innerHTML = '<div class="loading"><div class="spinner"></div></div>';
    
    try {
        const query = new URLSearchParams();
        if (params.q) query.set('q', params.q);
        if (params.page) query.set('page', params.page);
        
        const data = await apiCall('GET', `/admin/users?${query.toString()}`);
        const users = data.data || data || [];
        const pagination = data.links || null;
        
        container.innerHTML = `
            <div class="toolbar">
                <div class="toolbar-left">
                    <div class="search-box">
                        <span class="search-icon">🔍</span>
                        <input type="text" placeholder="Tìm tên, email..." id="user-search" value="${escapeHtml(params.q || '')}" onkeyup="if(event.key==='Enter') searchUsers()">
                    </div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-body no-padding">
                    <div class="table-container">
                        <table>
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Người dùng</th>
                                    <th>Email</th>
                                    <th>Admin</th>
                                    <th>Số đơn</th>
                                    <th>Ngày tham gia</th>
                                    <th>Thao tác</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${users.map(u => html`
                                    <tr>
                                        <td>${u.id}</td>
                                        <td>
                                            <div style="display:flex;align-items:center;gap:8px;">
                                                <span class="user-avatar-sm">${getInitials(u.name)}</span>
                                                <span>${escapeHtml(u.name)}</span>
                                            </div>
                                        </td>
                                        <td>${escapeHtml(u.email)}</td>
                                        <td>
                                            <span class="status-badge ${u.is_admin ? 'status-delivered' : 'status-pending'}">
                                                ${u.is_admin ? 'Admin' : 'User'}
                                            </span>
                                        </td>
                                        <td>${u.orders_count || 0}</td>
                                        <td>${formatDateShort(u.created_at)}</td>
                                        <td>
                                            <div class="actions">
                                                <button class="btn btn-sm btn-${u.is_admin ? 'warning' : 'success'}" onclick="toggleAdmin(${u.id}, ${u.is_admin})">
                                                    ${u.is_admin ? 'Hủy Admin' : 'Set Admin'}
                                                </button>
                                                <button class="btn btn-sm btn-danger" onclick="confirmDeleteUser(${u.id}, '${escapeHtml(u.name).replace(/'/g, "\\'")}')">Xóa</button>
                                            </div>
                                        </td>
                                    </tr>
                                `).join('')}
                                ${users.length === 0 ? '<tr><td colspan="7" style="text-align:center;padding:40px;color:var(--gray-500)">Không tìm thấy người dùng</td></tr>' : ''}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            
            ${pagination ? renderPagination(pagination, 'users') : ''}
        `;
    } catch (err) {
        container.innerHTML = `<div class="empty-state"><div class="empty-icon">⚠️</div><h3>Lỗi</h3><p>${escapeHtml(err.message)}</p></div>`;
        showToast(err.message, 'error');
    }
}

function searchUsers() {
    const q = $('#user-search')?.value || '';
    navigate('users', { q });
}

async function toggleAdmin(userId, isCurrentlyAdmin) {
    if (!confirm(`Xác nhận ${isCurrentlyAdmin ? 'hủy quyền admin' : 'cấp quyền admin'} cho người dùng này?`)) return;
    
    try {
        await apiCall('POST', `/admin/users/${userId}/toggle-admin`);
        showToast(isCurrentlyAdmin ? 'Đã hủy quyền admin' : 'Đã cấp quyền admin');
        navigate('users');
    } catch (err) {
        showToast(err.message, 'error');
    }
}

function confirmDeleteUser(id, name) {
    openModal(`
        <div class="modal-header">
            <h3>Xác nhận xóa</h3>
            <button class="modal-close" onclick="closeModal()">×</button>
        </div>
        <div class="modal-body">
            <p>Bạn có chắc chắn muốn xóa người dùng <strong>${escapeHtml(name)}</strong>?</p>
            <p style="color:var(--gray-500);font-size:13px;margin-top:8px;">Hành động này không thể hoàn tác.</p>
        </div>
        <div class="modal-footer">
            <button class="btn btn-ghost" onclick="closeModal()">Hủy</button>
            <button class="btn btn-danger" onclick="deleteUser(${id})">Xóa</button>
        </div>
    `, 'modal-sm');
}

async function deleteUser(id) {
    try {
        await apiCall('DELETE', `/admin/users/${id}`);
        showToast('Xóa người dùng thành công');
        closeModal();
        navigate('users');
    } catch (err) {
        showToast(err.message, 'error');
    }
}

// ====== Reviews ======
async function renderReviews(container, params = {}) {
    container.innerHTML = '<div class="loading"><div class="spinner"></div></div>';
    
    try {
        // Get reviews from product stats
        const stats = await apiCall('GET', '/admin/stats');
        const reviewStats = stats.review_stats || {};
        const productReviews = stats.product_reviews || [];
        
        container.innerHTML = `
            <div class="stats-grid" style="grid-template-columns:repeat(auto-fit,minmax(180px,1fr));">
                <div class="stat-card">
                    <div class="stat-header">
                        <span class="stat-label">Tổng đánh giá</span>
                        <div class="stat-icon icon-primary">⭐</div>
                    </div>
                    <div class="stat-value">${reviewStats.total_reviews || 0}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-header">
                        <span class="stat-label">Điểm TB</span>
                        <div class="stat-icon icon-warning">📊</div>
                    </div>
                    <div class="stat-value">${reviewStats.avg_rating || 0}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-header">
                        <span class="stat-label">5 ★</span>
                        <div class="stat-icon icon-success">👍</div>
                    </div>
                    <div class="stat-value">${reviewStats.five_stars || 0}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-header">
                        <span class="stat-label">1-2 ★</span>
                        <div class="stat-icon icon-danger">👎</div>
                    </div>
                    <div class="stat-value">${(reviewStats.one_star || 0) + (reviewStats.two_stars || 0)}</div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-header">
                    <h3>Đánh giá theo sản phẩm</h3>
                </div>
                <div class="card-body no-padding">
                    <div class="table-container">
                        <table>
                            <thead>
                                <tr>
                                    <th>Sản phẩm</th>
                                    <th>Điểm TB</th>
                                    <th>5★</th>
                                    <th>4★</th>
                                    <th>3★</th>
                                    <th>2★</th>
                                    <th>1★</th>
                                    <th>Tổng</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${productReviews.map(pr => html`
                                    <tr>
                                        <td>
                                            <div style="display:flex;align-items:center;gap:10px;">
                                                ${pr.image ? `<img src="${escapeHtml(pr.image)}" class="product-thumb">` : `<div class="product-thumb-placeholder">📷</div>`}
                                                <span>${escapeHtml(pr.name)}</span>
                                            </div>
                                        </td>
                                        <td><span class="stars">${renderStars(pr.avg_rating)}</span> ${pr.avg_rating}</td>
                                        <td>${pr.ratings?.[5] || 0}</td>
                                        <td>${pr.ratings?.[4] || 0}</td>
                                        <td>${pr.ratings?.[3] || 0}</td>
                                        <td>${pr.ratings?.[2] || 0}</td>
                                        <td>${pr.ratings?.[1] || 0}</td>
                                        <td><strong>${pr.total_reviews}</strong></td>
                                    </tr>
                                `).join('')}
                                ${productReviews.length === 0 ? '<tr><td colspan="8" style="text-align:center;padding:40px;color:var(--gray-500)">Chưa có đánh giá</td></tr>' : ''}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        `;
    } catch (err) {
        container.innerHTML = `<div class="empty-state"><div class="empty-icon">⚠️</div><h3>Lỗi</h3><p>${escapeHtml(err.message)}</p></div>`;
        showToast(err.message, 'error');
    }
}

// ====== Pagination ======
function renderPagination(links, pageType) {
    if (!links || links.length <= 3) return '';
    
    const getParams = (url) => {
        if (!url) return {};
        const u = new URL(url, window.location.origin);
        return Object.fromEntries(u.searchParams.entries());
    };
    
    return `
    <div class="pagination">
        ${links.map(link => {
            const active = link.active ? 'active' : '';
            const disabled = link.url === null ? 'disabled' : '';
            const label = link.label === '&laquo;' ? '«' : link.label === '&raquo;' ? '»' : link.label;
            const params = link.url ? getParams(link.url) : {};
            
            if (disabled) {
                return `<span class="page-item disabled">${escapeHtml(label)}</span>`;
            }
            
            const onclick = `navigate('${pageType}', ${JSON.stringify({ ...currentPageData, ...params, page: params.page || 1 })})`;
            return `<button class="page-item ${active}" onclick="${onclick.replace(/"/g, "'")}">${escapeHtml(label)}</button>`;
        }).join('')}
    </div>`;
}

// ====== Login Page ======
function showLoginPage() {
    const app = $('#app');
    if (!app) return;
    
    app.innerHTML = `
        <div class="login-page">
            <div class="login-container">
                <h1>🛒 Admin Panel</h1>
                <p class="subtitle">Đăng nhập để quản lý cửa hàng</p>
                <div class="login-error" id="login-error"></div>
                <form id="login-form" onsubmit="handleLogin(event)">
                    <div class="form-group">
                        <label>Email</label>
                        <input type="email" id="login-email" placeholder="admin@email.com" required autocomplete="email">
                    </div>
                    <div class="form-group">
                        <label>Mật khẩu</label>
                        <input type="password" id="login-password" placeholder="••••••••" required autocomplete="current-password">
                    </div>
                    <button type="submit" class="btn btn-primary btn-lg btn-block" id="login-btn">Đăng nhập</button>
                </form>
            </div>
        </div>
    `;
}

async function handleLogin(event) {
    event.preventDefault();
    const email = $('#login-email').value;
    const password = $('#login-password').value;
    const btn = $('#login-btn');
    const errorEl = $('#login-error');
    
    btn.disabled = true;
    btn.textContent = 'Đang đăng nhập...';
    errorEl.classList.remove('show');
    
    try {
        await login(email, password);
        render();
        showToast('Đăng nhập thành công');
    } catch (err) {
        errorEl.textContent = err.message;
        errorEl.classList.add('show');
        btn.disabled = false;
        btn.textContent = 'Đăng nhập';
    }
}

// ====== Init ======
document.addEventListener('DOMContentLoaded', () => {
    // Check for stored user
    const storedUser = localStorage.getItem('admin_user');
    if (storedUser) {
        try {
            ADMIN_USER = JSON.parse(storedUser);
        } catch (e) {}
    }
    
    render();
});