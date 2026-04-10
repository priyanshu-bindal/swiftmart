"use client";

import { Filter, Download, Eye, X } from "lucide-react";
import { useEffect, useState, useMemo } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase/client";
import toast from "react-hot-toast";

export default function OrdersPage() {
  const router = useRouter();
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Filters and Pagination
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("All Orders");
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;
  
  // Date range
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");

  useEffect(() => {
    fetchOrders();
  }, []);

  const fetchOrders = async () => {
    try {
      console.log('--- fetchOrders TICK ---');
      setLoading(true);
      // STEP 1: Fetch orders alone
      const { data: ordersData, error } = await supabase
        .from("orders")
        .select('*')
        .order("created_at", { ascending: false });

      console.log('ordersData count:', ordersData?.length, 'error:', error?.message);

      if (error) {
        toast.error(`Database Error: ${error.message}`);
        console.error("fetchOrders error:", error);
        setLoading(false);
        return;
      }

      if (!ordersData || ordersData.length === 0) {
        console.log('Empty ordersData returned by Supabase!');
        setOrders([]);
        setLoading(false);
        return;
      }

    // STEP 2: Extract unique user_ids from orders
    const userIds = [...new Set(ordersData.map(o => o.user_id).filter(Boolean))];

    // STEP 3: Fetch profiles safely
    let profilesData: any[] = [];
    if (userIds.length > 0) {
      const { data, error: profErr } = await supabase
        .from('profiles')
        .select('id, full_name, email, avatar_url')
        .in('id', userIds);
      
      if (profErr) console.error("Profiles fetch error:", profErr);
      if (data) profilesData = data;
    }

    const profilesMap: Record<string, any> = {};
    profilesData.forEach(p => {
      profilesMap[p.id] = p;
    });

    // STEP 4: Fetch items count safely
    const orderIds = ordersData.map(o => o.id);
    let itemsCountData: any[] = [];
    if (orderIds.length > 0) {
      const { data, error: itemErr } = await supabase
        .from('order_items')
        .select('order_id')
        .in('order_id', orderIds);
        
      if (itemErr) console.error("Items count error:", itemErr);
      if (data) itemsCountData = data;
    }

    const itemCountMap: Record<string, number> = {};
    itemsCountData.forEach(item => {
      itemCountMap[item.order_id] = (itemCountMap[item.order_id] || 0) + 1;
    });

      // STEP 5: Merge profile data and count into each order
      const ordersWithProfiles = ordersData.map(order => ({
        ...order,
        profile: profilesMap[order.user_id] || null,
        itemCount: itemCountMap[order.id] || 0,
      }));

      console.log('Final orders to set:', ordersWithProfiles.length);
      setOrders(ordersWithProfiles);
      setLoading(false);
    } catch (err: any) {
      console.error("fetchOrders unexpected FATAL JS ERROR:", err);
      setLoading(false);
    }
  };

  const statusMap: Record<string, string> = {
    "Pending": "pending",
    "Confirmed": "confirmed",
    "In Transit": "in_transit", 
    "Delivered": "delivered",
    "Cancelled": "cancelled"
  };

  const getStatusStyles = (status: string) => {
    if (!status) return "bg-slate-100 text-slate-700 border border-slate-300";
    switch(status.toLowerCase()) {
      case 'pending':
      case 'preparing': return "bg-amber-50 text-amber-600 border border-amber-300 hover:bg-amber-100";
      case 'confirmed': return "bg-blue-50 text-blue-700 border border-blue-300 hover:bg-blue-100";
      case 'in_transit':
      case 'out_for_delivery': return "bg-purple-50 text-purple-700 border border-purple-300 hover:bg-purple-100";
      case 'delivered': return "bg-emerald-50 text-emerald-700 border border-emerald-300 hover:bg-emerald-100";
      case 'cancelled': return "bg-red-50 text-red-700 border border-red-300 hover:bg-red-100";
      default: return "bg-slate-50 text-slate-700 border border-slate-300 hover:bg-slate-100";
    }
  };

  const getStatusLabel = (status: string) => {
    if (!status) return 'Unknown';
    const labels: Record<string, string> = {
      pending: 'Pending',
      preparing: 'Pending',
      confirmed: 'Confirmed', 
      in_transit: 'Out for Delivery',
      out_for_delivery: 'Out for Delivery',
      delivered: 'Delivered',
      cancelled: 'Cancelled'
    };
    return labels[status.toLowerCase()] || status;
  };

  const isStepReached = (currentStatus: string, step: string) => {
    if (!currentStatus) return false;
    const order = ['pending', 'confirmed', 'in_transit', 'delivered'];
    const cs = currentStatus.toLowerCase();
    const norm = cs === 'preparing' ? 'pending' : (cs === 'out_for_delivery' ? 'in_transit' : cs);
    return order.indexOf(norm) >= order.indexOf(step.toLowerCase());
  };

  const handleStatusUpdate = async (orderId: string, newStatus: string) => {
    // Map UI statuses back to DB enum values
    let dbStatus = newStatus.toUpperCase();
    if (newStatus === 'pending') dbStatus = 'PREPARING';
    if (newStatus === 'in_transit') dbStatus = 'OUT_FOR_DELIVERY';

    // 1. Optimistic UI update
    setOrders(prev =>
      prev.map(o => o.id === orderId ? { ...o, status: dbStatus } : o)
    );

    // 2. Write to Supabase
    const { error } = await supabase
      .from('orders')
      .update({ status: dbStatus })
      .eq('id', orderId);

    if (error) {
      console.error('Status update failed:', error);
      toast.error('Failed to update order status. Please try again.');
      fetchOrders();
    } else {
      toast.success(`Order marked as ${getStatusLabel(dbStatus)}`);
    }
  };

  const filteredOrders = useMemo(() => {
    let result = orders;

    // Search filter
    if (searchQuery) {
      const lower = searchQuery.toLowerCase();
      result = result.filter(o => 
        o.id.toLowerCase().includes(lower) || 
        (o.profile?.full_name || "").toLowerCase().includes(lower)
      );
    }

    // Status filter
    if (statusFilter !== "All Orders") {
      const targetStatus = statusMap[statusFilter];
      result = result.filter(o => {
        const cs = o.status?.toLowerCase();
        const norm = (cs === "preparing" ? "pending" : (cs === "out_for_delivery" ? "in_transit" : cs));
        return norm === targetStatus;
      });
    }

    // Date range filter
    if (startDate) {
      result = result.filter(o => new Date(o.created_at) >= new Date(startDate));
    }
    if (endDate) {
      result = result.filter(o => new Date(o.created_at) <= new Date(endDate + 'T23:59:59'));
    }

    return result;
  }, [orders, searchQuery, statusFilter, startDate, endDate]);

  const totalPages = Math.ceil(filteredOrders.length / itemsPerPage) || 1;
  const paginatedOrders = filteredOrders.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);

  // Update effect to reset page when filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, statusFilter, startDate, endDate]);

  const formatDate = (dateString: string) => {
    const d = new Date(dateString);
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    let hours = d.getHours();
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    hours = hours ? hours : 12; // the hour '0' should be '12'
    const minutes = d.getMinutes().toString().padStart(2, '0');
    return `${d.getDate()} ${months[d.getMonth()]}, ${hours}:${minutes} ${ampm}`;
  };

  return (
    <>
      {/* TopBar override to use client state properly */}
      <header className="sticky top-0 w-full z-40 bg-white/80 backdrop-blur-xl border-b border-slate-100 flex justify-between items-center h-16 px-8">
        <div className="flex items-center gap-4 flex-1">
          <div className="relative w-full max-w-md">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="lucide lucide-search absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <input
              type="text"
              placeholder="Search orders by ID or customer..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-slate-50 border-none rounded-xl py-2 pl-9 pr-4 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all placeholder:text-slate-400"
            />
          </div>
        </div>
        <div className="flex items-center gap-3">
           <div className="w-8 h-8 rounded-full bg-indigo-100 border border-indigo-200 flex items-center justify-center text-indigo-700 text-xs font-bold">A</div>
        </div>
      </header>
      
      <main className="p-8 bg-surface min-h-screen relative">
        <div className="flex justify-between items-end mb-8">
          <div>
            <h1 className="text-2xl font-bold text-on-surface tracking-tight">
              Orders Management
            </h1>
            <p className="text-sm text-on-surface-variant mt-1">
              Track, manage and update all customer orders.
            </p>
          </div>
          <div className="flex flex-col items-end gap-3">
             <div className="flex gap-2 text-sm text-slate-600 font-medium items-center">
                Date: 
                <input type="date" value={startDate} onChange={e => setStartDate(e.target.value)} className="rounded-md border border-slate-200 px-2 py-1 bg-white outline-none" />
                to
                <input type="date" value={endDate} onChange={e => setEndDate(e.target.value)} className="rounded-md border border-slate-200 px-2 py-1 bg-white outline-none" />
             </div>
            <div className="flex gap-3">
              <button className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-surface-container-lowest border border-outline-variant/20 text-on-surface text-sm font-semibold hover:bg-surface-container-low transition-colors shadow-sm">
                <Filter size={16} />
                Filters
              </button>
              <button onClick={() => fetchOrders()} className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-gradient-to-br from-primary to-primary-container text-white text-sm font-semibold shadow-lg shadow-indigo-500/10 transition-all hover:shadow-indigo-500/20">
                <Download size={16} />
                Refetch Data
              </button>
            </div>
          </div>
        </div>

        {/* Status Filter Tabs */}
        <div className="flex gap-2 mb-6 bg-surface-container-lowest rounded-xl p-2 shadow-sm w-fit overflow-x-auto max-w-full">
          {["All Orders", "Pending", "Confirmed", "In Transit", "Delivered", "Cancelled"].map(
            (tab, i) => (
              <button
                key={tab}
                onClick={() => setStatusFilter(tab)}
                className={`px-4 py-2 rounded-lg text-xs font-semibold transition-colors shrink-0 ${
                  statusFilter === tab
                    ? "bg-primary text-white shadow-sm"
                    : "text-on-surface-variant hover:text-on-surface hover:bg-surface-container-low"
                }`}
              >
                {tab}
              </button>
            )
          )}
        </div>

        {/* Orders Table */}
        <div className="bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="bg-surface-container-low border-b border-slate-100">
                <tr>
                  {[
                    "Order ID",
                    "Customer",
                    "Items",
                    "Date",
                    "Amount",
                    "Status",
                    "",
                  ].map((h) => (
                    <th
                      key={h}
                      className="px-6 py-4 text-[11px] font-bold text-on-surface-variant uppercase tracking-wider"
                    >
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50">
                {loading ? (
                   Array(10).fill(0).map((_, i) => (
                      <tr key={`sk-${i}`}>
                        <td className="px-6 py-4"><div className="h-4 w-20 bg-slate-200 animate-pulse rounded" /></td>
                        <td className="px-6 py-4"><div className="flex items-center gap-3"><div className="w-8 h-8 rounded-full bg-slate-200 animate-pulse" /><div className="h-4 w-24 bg-slate-200 animate-pulse rounded" /></div></td>
                        <td className="px-6 py-4"><div className="h-4 w-12 bg-slate-200 animate-pulse rounded" /></td>
                        <td className="px-6 py-4"><div className="h-4 w-24 bg-slate-200 animate-pulse rounded" /></td>
                        <td className="px-6 py-4"><div className="h-4 w-16 bg-slate-200 animate-pulse rounded" /></td>
                        <td className="px-6 py-4"><div className="h-5 w-20 rounded-full bg-slate-200 animate-pulse" /></td>
                        <td className="px-6 py-4"></td>
                      </tr>
                   ))
                ) : paginatedOrders.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-6 py-8 text-center text-slate-500 text-sm">
                      No orders found matching the current filters.
                    </td>
                  </tr>
                ) : (
                  paginatedOrders.map((order) => {
                    const initials = order.profile?.full_name 
                      ? order.profile.full_name.split(" ").map((n: string) => n[0]).join("") 
                      : "??";

                    return (
                      <tr
                        key={order.id}
                        onClick={() => router.push(`/orders/${order.id}`)}
                        className="hover:bg-surface-container-low transition-colors group cursor-pointer"
                      >
                        <td className="px-6 py-4 font-bold text-indigo-600 text-sm">
                          #ORD-{order.id.slice(0, 8)}
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-3">
                            {order.profile?.avatar_url ? (
                               <img src={order.profile.avatar_url} alt="Avatar" className="w-8 h-8 rounded-full object-cover border border-slate-200" />
                            ) : (
                               <div className="w-8 h-8 rounded-full bg-indigo-100 flex items-center justify-center text-xs font-bold text-indigo-700">
                                 {initials.substring(0, 2).toUpperCase()}
                               </div>
                            )}
                            <div className="flex flex-col">
                              <span className="text-sm font-semibold text-on-surface">
                                {order.profile?.full_name || "Unknown"}
                              </span>
                              <span className="text-[10px] text-slate-500">
                                {order.profile?.email}
                              </span>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4 text-sm text-on-surface font-medium">
                          {order.itemCount || 0} item{(order.itemCount || 0) !== 1 ? 's' : ''}
                        </td>
                        <td className="px-6 py-4 text-xs text-on-surface-variant font-medium">
                          {formatDate(order.created_at)}
                        </td>
                        <td className="px-6 py-4 font-bold text-on-surface">
                          ₹{(order.total || 0).toFixed(2)}
                        </td>
                        <td className="px-6 py-4">
                          <select
                            value={(() => {
                              const cs = order.status?.toLowerCase();
                              return cs === 'preparing' ? 'pending' : (cs === 'out_for_delivery' ? 'in_transit' : cs);
                            })()}
                            onChange={(e) => handleStatusUpdate(order.id, e.target.value)}
                            onClick={(e) => e.stopPropagation()}
                            className={`appearance-none px-3 py-1.5 rounded-full text-[10px] font-bold uppercase tracking-wider outline-none cursor-pointer ${getStatusStyles(order.status)} transition-colors focus:ring-2 focus:ring-primary/40`}
                          >
                            <option value="pending">Pending</option>
                            <option value="confirmed">Confirmed</option>
                            <option value="in_transit">Out for Delivery</option>
                            <option value="delivered">Delivered</option>
                            <option value="cancelled">Cancelled</option>
                          </select>
                        </td>
                        <td className="px-6 py-4">
                          <button 
                            onClick={(e) => {
                              e.stopPropagation();
                              router.push(`/orders/${order.id}`);
                            }}
                            className="p-2 hover:bg-white rounded-lg transition-all text-slate-400 group-hover:text-indigo-600 shadow-sm opacity-0 group-hover:opacity-100 bg-slate-50 border border-slate-200"
                            title="View Details"
                          >
                            <Eye size={16} />
                          </button>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
          <div className="px-6 py-4 bg-surface-container-low/30 border-t border-slate-100 flex items-center justify-between">
            <span className="text-xs text-on-surface-variant font-medium">
              Page {currentPage} of {totalPages} ({filteredOrders.length} orders total)
            </span>
            <div className="flex gap-2">
              <button 
                 onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                 disabled={currentPage === 1}
                 className="px-3 py-1 rounded-lg border border-outline-variant/30 text-xs font-bold disabled:opacity-50 disabled:cursor-not-allowed hover:bg-surface-container-low transition-colors bg-white">
                Previous
              </button>
              <button 
                 onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                 disabled={currentPage === totalPages}
                 className="px-3 py-1 rounded-lg bg-white border border-outline-variant/30 text-xs font-bold shadow-sm hover:bg-surface-container-low disabled:opacity-50 disabled:cursor-not-allowed transition-colors">
                Next
              </button>
            </div>
          </div>
        </div>
      </main>
    </>
  );
}
