"use client";

import TopBar from "@/components/TopBar";
import {
  TrendingUp,
  ShoppingBasket,
  Truck,
  UserPlus,
  ChevronRight,
  MoreVertical,
} from "lucide-react";
import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase/client";
import { motion, Variants } from "framer-motion";

// For the Bar Chart Container
const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1, // PRD staggered list effect 
    },
  },
};

// For individual Bars
const barVariants: Variants = {
  hidden: { scaleY: 0, originY: 1 },
  visible: {
    scaleY: 1,
    transition: { type: "spring", stiffness: 100, damping: 15 }
  },
};

export default function DashboardPage() {
  const [loading, setLoading] = useState(true);

  // States for top cards
  const [weeklyRevenue, setWeeklyRevenue] = useState(0);
  const [ordersToday, setOrdersToday] = useState(0);
  const [activeDeliveries, setActiveDeliveries] = useState(0);
  const [newUsers, setNewUsers] = useState(0);

  // States for Bar Chart (Weekly Revenue)
  const [barData, setBarData] = useState<{ day: string; total: number; height: string }[]>([]);

  // States for Donut Chart
  const [orderStatusBreakdown, setOrderStatusBreakdown] = useState({
    delivered: 0,
    confirmed: 0,
    preparing: 0,
    cancelled: 0,
    total: 0,
  });

  // Recent orders
  const [recentOrders, setRecentOrders] = useState<any[]>([]);

  // Stock alerts
  const [stockAlerts, setStockAlerts] = useState<any[]>([]);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    setLoading(true);

    const now = new Date();

    const sevenDaysAgoDate = new Date();
    sevenDaysAgoDate.setDate(now.getDate() - 7);
    const sevenDaysAgo = sevenDaysAgoDate.toISOString();

    const todayMidnightDate = new Date();
    todayMidnightDate.setHours(0, 0, 0, 0);
    const todayMidnight = todayMidnightDate.toISOString();

    // 1. Weekly Revenue (Orders past 7 days)
    const { data: weeklyOrders } = await supabase
      .from("orders")
      .select("total, created_at")
      .gte("created_at", sevenDaysAgo);

    let rev = 0;
    const dayTotals = new Map<number, number>(); // day of week (0-6)

    // Initialize dayTotals for the last 7 days including today
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(now.getDate() - i);
      dayTotals.set(d.getDay(), 0);
    }

    if (weeklyOrders) {
      rev = weeklyOrders.reduce((sum, order) => sum + (order.total || 0), 0);

      weeklyOrders.forEach((o) => {
        const orderDate = new Date(o.created_at);
        const day = orderDate.getDay();
        if (dayTotals.has(day)) {
          dayTotals.set(day, dayTotals.get(day)! + (o.total || 0));
        }
      });
    }
    setWeeklyRevenue(rev);

    const dayNames = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
    const orderedBars = [];

    let maxTotal = 0;
    // We want the last 7 days ending in "today"
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(now.getDate() - i);
      const dy = d.getDay();
      const pt = dayTotals.get(dy) || 0;
      if (pt > maxTotal) maxTotal = pt;
      orderedBars.push({
        day: dayNames[dy],
        total: pt,
        height: "0%",
      });
    }

    // Calculate heights
    setBarData(
      orderedBars.map((b) => ({
        ...b,
        height: maxTotal === 0 ? "5%" : `${Math.max(5, (b.total / maxTotal) * 100)}%`,
      }))
    );

    // 2. Total Orders Today
    const { count: countToday } = await supabase
      .from("orders")
      .select("*", { count: "exact", head: true })
      .gte("created_at", todayMidnight);
    setOrdersToday(countToday || 0);

    // 3. Active Deliveries
    const { count: countActive } = await supabase
      .from("orders")
      .select("*", { count: "exact", head: true })
      .eq("status", "out_for_delivery");
    setActiveDeliveries(countActive || 0);

    // 4. New Users
    const { count: countNewUsers } = await supabase
      .from("profiles")
      .select("*", { count: "exact", head: true })
      .gte("created_at", sevenDaysAgo);
    setNewUsers(countNewUsers || 0);

    // 5. Order Breakdown Donut (All orders status count)
    const { data: allOrders } = await supabase.from("orders").select("status");
    const counts = { delivered: 0, confirmed: 0, preparing: 0, cancelled: 0, total: 0 };
    if (allOrders) {
      counts.total = allOrders.length;
      allOrders.forEach((o) => {
        const orderStatus = o.status?.toLowerCase() || "";
        if (orderStatus === "delivered") counts.delivered++;
        if (orderStatus === "confirmed") counts.confirmed++;
        if (orderStatus === "preparing") counts.preparing++;
        if (orderStatus === "cancelled") counts.cancelled++;
      });
    }
    if (counts.total === 0) counts.total = 1; // prevent divide by zero
    setOrderStatusBreakdown(counts);

    // 6. Recent Orders (limit 5)
    // We need to fetch order_items count. Since Supabase JS client doesn't directly support 
    // joining and counting at the same time simply, we will fetch order_items separately or join them.
    const { data: recentOrdersData } = await supabase
      .from("orders")
      .select(`
        id, 
        total, 
        status,
        profiles (full_name, email, avatar_url),
        order_items (id)
      `)
      .order("created_at", { ascending: false })
      .limit(5);

    if (recentOrdersData) {
      const formatted = recentOrdersData.map((o: any) => {
        const customer = o.profiles?.full_name || "Unknown";
        let initials = "??";
        if (o.profiles?.full_name) {
          const parts = o.profiles.full_name.split(" ");
          initials = parts.length > 1 ? parts[0][0] + parts[1][0] : parts[0][0];
        }

        let statusColor = "bg-slate-50 text-slate-600";
        if (o.status === "delivered") statusColor = "bg-emerald-50 text-emerald-600";
        if (o.status === "confirmed") statusColor = "bg-indigo-50 text-indigo-600";
        if (o.status === "preparing") statusColor = "bg-amber-50 text-amber-600";
        if (o.status === "out_for_delivery") statusColor = "bg-purple-50 text-purple-600";
        if (o.status === "cancelled") statusColor = "bg-red-50 text-red-600";

        return {
          id: o.id,
          customer,
          initials: initials.toUpperCase(),
          product: `${o.order_items?.length || 0} items`,
          amount: `₹${(o.total || 0).toFixed(2)}`,
          status: o.status,
          statusColor,
        };
      });
      setRecentOrders(formatted);
    }

    // 7. Stock Alerts
    const { data: lowStock } = await supabase
      .from("products")
      .select("name, stock_quantity, image_url")
      .lt("stock_quantity", 10)
      .order("stock_quantity", { ascending: true })
      .limit(5);

    if (lowStock) {
      const alerts = lowStock.map((p) => ({
        name: p.name,
        count: `${p.stock_quantity} Items left`,
        alertColor: p.stock_quantity < 5 ? "text-red-500" : "text-amber-500",
      }));
      setStockAlerts(alerts);
    }

    setLoading(false);
  };

  const getStrokeParts = () => {
    const total = orderStatusBreakdown.total > 0 ? orderStatusBreakdown.total : 1;
    const deliveredPct = Math.round((orderStatusBreakdown.delivered / total) * 100);
    const confirmedPct = Math.round((orderStatusBreakdown.confirmed / total) * 100);
    const preparingPct = Math.round((orderStatusBreakdown.preparing / total) * 100);
    const cancelledPct = Math.round((orderStatusBreakdown.cancelled / total) * 100);

    return [
      { color: "#10b981", dash: deliveredPct, offset: 0, label: `Delivered (${deliveredPct}%)`, bg: 'bg-emerald-500' },
      { color: "#233a87", dash: confirmedPct, offset: -deliveredPct, label: `Confirmed (${confirmedPct}%)`, bg: 'bg-indigo-600' },
      { color: "#f59e0b", dash: preparingPct, offset: -(deliveredPct + confirmedPct), label: `Preparing (${preparingPct}%)`, bg: 'bg-amber-500' },
      { color: "#ef4444", dash: cancelledPct, offset: -(deliveredPct + confirmedPct + preparingPct), label: `Cancelled (${cancelledPct}%)`, bg: 'bg-red-500' },
    ];
  };

  const strokes = getStrokeParts();

  return (
    <>
      <TopBar placeholder="Search orders, customers, or items..." />
      <main className="p-8 bg-surface min-h-screen">
        {/* Page Title */}
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-on-surface tracking-tight">
            Dashboard Overview
          </h1>
          <p className="text-sm text-on-surface-variant mt-1">
            Welcome back! Here&apos;s what&apos;s happening today.
          </p>
        </div>

        {/* Stat Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-outline-variant/10 flex flex-col justify-between">
            <div className="flex justify-between items-start mb-4">
              <div className="p-2 bg-indigo-50 rounded-lg">
                <TrendingUp size={20} className="text-indigo-600" />
              </div>
            </div>
            <div>
              <p className="text-on-surface-variant text-xs font-semibold uppercase tracking-wider mb-1">
                Weekly Revenue
              </p>
              {loading ? (
                <div className="h-8 w-32 bg-slate-200 animate-pulse rounded"></div>
              ) : (
                <h3 className="text-2xl font-bold text-on-surface">
                  ₹{weeklyRevenue.toFixed(2)}
                </h3>
              )}
            </div>
          </div>

          <div className="bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-outline-variant/10 flex flex-col justify-between">
            <div className="flex justify-between items-start mb-4">
              <div className="p-2 bg-blue-50 rounded-lg">
                <ShoppingBasket size={20} className="text-blue-600" />
              </div>
            </div>
            <div>
              <p className="text-on-surface-variant text-xs font-semibold uppercase tracking-wider mb-1">
                Total Orders Today
              </p>
              {loading ? (
                <div className="h-8 w-24 bg-slate-200 animate-pulse rounded"></div>
              ) : (
                <h3 className="text-2xl font-bold text-on-surface">{ordersToday}</h3>
              )}
            </div>
          </div>

          <div className="bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-outline-variant/10 flex flex-col justify-between">
            <div className="flex justify-between items-start mb-4">
              <div className="p-2 bg-amber-50 rounded-lg">
                <Truck size={20} className="text-amber-600" />
              </div>
            </div>
            <div>
              <p className="text-on-surface-variant text-xs font-semibold uppercase tracking-wider mb-1">
                Active Deliveries
              </p>
              {loading ? (
                <div className="h-8 w-24 bg-slate-200 animate-pulse rounded"></div>
              ) : (
                <h3 className="text-2xl font-bold text-on-surface">{activeDeliveries}</h3>
              )}
            </div>
          </div>

          <div className="bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-outline-variant/10 flex flex-col justify-between">
            <div className="flex justify-between items-start mb-4">
              <div className="p-2 bg-purple-50 rounded-lg">
                <UserPlus size={20} className="text-purple-600" />
              </div>
            </div>
            <div>
              <p className="text-on-surface-variant text-xs font-semibold uppercase tracking-wider mb-1">
                New Users
              </p>
              {loading ? (
                <div className="h-8 w-24 bg-slate-200 animate-pulse rounded"></div>
              ) : (
                <h3 className="text-2xl font-bold text-on-surface">{newUsers}</h3>
              )}
            </div>
          </div>
        </div>

        {/* Charts Row */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
          {/* Weekly Revenue Bar Chart */}
          <div className="lg:col-span-2 bg-surface-container-lowest p-8 rounded-xl shadow-sm border border-outline-variant/10">
            <div className="flex items-center justify-between mb-8">
              <div>
                <h4 className="text-lg font-bold text-on-surface">
                  Weekly Revenue Analysis
                </h4>
                <p className="text-sm text-on-surface-variant">
                  Transaction growth over the last 7 days
                </p>
              </div>
            </div>
            {loading ? (
              <div className="h-64 w-full bg-slate-100 animate-pulse rounded-lg flex items-end px-2 gap-4 pb-4">
                {[35, 60, 45, 75, 55, 80, 40].map((height, i) => (
                  <div key={i} className="flex-1 bg-slate-200 rounded-t-lg" style={{ height: `${height}%` }}></div>
                ))}
              </div>
            ) : (
              <>
                <motion.div
                  variants={containerVariants}
                  initial="hidden"
                  whileInView="visible"
                  viewport={{ once: true, margin: "-50px" }}
                  className="h-64 relative flex items-end justify-between px-2 gap-4"
                >
                  <div className="absolute inset-0 flex flex-col justify-between pointer-events-none opacity-20">
                    {[0, 1, 2, 3].map((i) => (
                      <div key={i} className="border-t border-slate-300 w-full" />
                    ))}
                  </div>
                  {barData.map((b, i) => (
                    <motion.div
                      key={i}
                      variants={barVariants}
                      className="flex-1 bg-gradient-to-t from-primary to-primary-container rounded-t-lg transition-colors hover:opacity-80"
                      style={{ height: b.height }}
                      title={`₹${b.total.toFixed(2)}`}
                    />
                  ))}
                </motion.div>
                <div className="flex justify-between mt-4 px-2">
                  {barData.map((b) => (
                    <span key={b.day} className="text-xs font-bold text-slate-400">
                      {b.day}
                    </span>
                  ))}
                </div>
              </>
            )}
          </div>

          {/* Donut Chart */}
          <div className="bg-surface-container-lowest p-8 rounded-xl shadow-sm border border-outline-variant/10 flex flex-col items-center">
            <h4 className="text-lg font-bold text-on-surface w-full mb-6">
              Order Breakdown
            </h4>
            <div className="relative w-48 h-48 mb-8">
              <svg
                className="w-full h-full -rotate-90"
                viewBox="0 0 36 36"
              >
                {strokes.map((s) => (
                  s.dash > 0 && (
                    <motion.path
                      key={s.color}
                      initial={{ strokeDasharray: "0, 100" }}
                      whileInView={{ strokeDasharray: `${s.dash}, 100` }}
                      viewport={{ once: true, margin: "-50px" }}
                      transition={{ duration: 0.8, ease: "easeOut" }}
                      d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                      fill="transparent"
                      stroke={s.color}
                      strokeWidth="4"
                      strokeDashoffset={s.offset}
                    />
                  )
                ))}
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <motion.span
                  initial={{ scale: 0 }}
                  whileInView={{ scale: 1 }}
                  viewport={{ once: true }}
                  transition={{ type: "spring", stiffness: 200, damping: 10, delay: 0.2 }}
                  className="text-2xl font-extrabold text-on-surface"
                >
                  {orderStatusBreakdown.total > 1 ? orderStatusBreakdown.total : (orderStatusBreakdown.delivered + orderStatusBreakdown.confirmed + orderStatusBreakdown.preparing + orderStatusBreakdown.cancelled)}
                </motion.span>
                <span className="text-[10px] uppercase font-bold text-slate-400 mt-1">
                  Total
                </span>
              </div>
            </div>
            <div className="w-full grid grid-cols-2 gap-3">
              {strokes.map((s) => (
                <div key={s.label} className="flex items-center gap-2">
                  <div className={`w-3 h-3 rounded-full ${s.bg}`} />
                  <span className="text-[11px] font-bold text-on-surface-variant uppercase">
                    {s.label}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Bottom Row */}
        <div className="grid grid-cols-1 xl:grid-cols-4 gap-8">
          {/* Recent Orders Table */}
          <div className="xl:col-span-3 bg-surface-container-lowest rounded-xl shadow-sm border border-outline-variant/10 overflow-hidden">
            <div className="p-6 flex items-center justify-between border-b border-slate-50">
              <h4 className="text-lg font-bold text-on-surface">
                Recent Orders
              </h4>
              <button className="text-indigo-600 text-sm font-bold hover:underline">
                View All Orders
              </button>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left">
                <thead className="bg-surface-container-low">
                  <tr>
                    {[
                      "Order ID",
                      "Customer",
                      "Product",
                      "Amount",
                      "Status",
                      "",
                    ].map((h) => (
                      <th
                        key={h}
                        className="px-6 py-4 text-[10px] font-extrabold text-slate-500 uppercase tracking-widest"
                      >
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-50">
                  {loading ? (
                    Array(5).fill(0).map((_, i) => (
                      <tr key={i}>
                        <td className="px-6 py-4"><div className="h-4 w-20 bg-slate-200 animate-pulse rounded" /></td>
                        <td className="px-6 py-4"><div className="h-8 w-32 bg-slate-200 animate-pulse rounded" /></td>
                        <td className="px-6 py-4"><div className="h-4 w-24 bg-slate-200 animate-pulse rounded" /></td>
                        <td className="px-6 py-4"><div className="h-4 w-16 bg-slate-200 animate-pulse rounded" /></td>
                        <td className="px-6 py-4"><div className="h-6 w-20 bg-slate-200 animate-pulse rounded-full" /></td>
                        <td className="px-6 py-4"></td>
                      </tr>
                    ))
                  ) : recentOrders.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-6 py-8 text-center text-slate-500 text-sm">
                        No recent orders found.
                      </td>
                    </tr>
                  ) : (
                    recentOrders.map((order) => (
                      <tr
                        key={order.id}
                        className="hover:bg-slate-50 transition-colors"
                      >
                        <td className="px-6 py-4 font-bold text-indigo-600">
                          #ORD-{order.id.slice(0, 8)}
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-3">
                            <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-xs font-bold text-slate-600">
                              {order.initials}
                            </div>
                            <span className="text-sm font-semibold">
                              {order.customer}
                            </span>
                          </div>
                        </td>
                        <td className="px-6 py-4 text-sm">{order.product}</td>
                        <td className="px-6 py-4 font-bold">{order.amount}</td>
                        <td className="px-6 py-4">
                          <span
                            className={`px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${order.statusColor}`}
                          >
                            {order.status}
                          </span>
                        </td>
                        <td className="px-6 py-4">
                          <button className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                            <MoreVertical
                              size={16}
                              className="text-slate-400"
                            />
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>

          {/* Stock Alerts */}
          <div className="bg-surface-container-lowest rounded-xl shadow-sm border border-outline-variant/10 p-6 h-fit">
            <div className="flex items-center justify-between mb-6">
              <h4 className="text-lg font-bold text-on-surface">
                Stock Alerts
              </h4>
              <span className="px-2 py-0.5 bg-red-100 text-red-600 text-[10px] font-black rounded-full">
                {stockAlerts.length} LOW
              </span>
            </div>
            <div className="space-y-4">
              {loading ? (
                Array(3).fill(0).map((_, i) => (
                  <div key={i} className="p-4 bg-surface-container-low rounded-xl flex items-center gap-3">
                    <div className="w-10 h-10 bg-slate-200 animate-pulse rounded-lg" />
                    <div className="flex-1 space-y-2">
                      <div className="h-3 w-3/4 bg-slate-200 animate-pulse rounded" />
                      <div className="h-2 w-1/2 bg-slate-200 animate-pulse rounded" />
                    </div>
                  </div>
                ))
              ) : stockAlerts.length === 0 ? (
                <div className="text-center text-slate-500 text-sm py-4">All stock looks good!</div>
              ) : (
                stockAlerts.map((item) => (
                  <div
                    key={item.name}
                    className="p-4 bg-surface-container-low rounded-xl flex items-center justify-between group cursor-pointer hover:bg-secondary-container/10 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-lg bg-white border border-slate-100 flex items-center justify-center text-slate-400 text-xs font-bold overflow-hidden">
                        📦
                      </div>
                      <div>
                        <p className="text-sm font-bold text-on-surface truncate max-w-[120px]">
                          {item.name}
                        </p>
                        <p
                          className={`text-[10px] font-bold uppercase tracking-wide ${item.alertColor}`}
                        >
                          {item.count}
                        </p>
                      </div>
                    </div>
                    <ChevronRight
                      size={16}
                      className="text-slate-400 group-hover:text-indigo-600 transition-colors shrink-0"
                    />
                  </div>
                ))
              )}
              <button className="w-full py-3 mt-2 text-xs font-bold bg-secondary-container text-on-secondary-container rounded-xl shadow-sm hover:brightness-95 transition-all">
                Restock Inventory
              </button>
            </div>
          </div>
        </div>
      </main>
    </>
  );
}
