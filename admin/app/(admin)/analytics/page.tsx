"use client";

import { Download, TrendingUp, MoreVertical, ArrowUpRight } from "lucide-react";
import { useEffect, useState, useMemo } from "react";
import { supabase } from "@/lib/supabase/client";

export default function AnalyticsPage() {
  const [loading, setLoading] = useState(true);
  
  // Data State
  const [totalRevenue, setTotalRevenue] = useState(0);
  const [avgDaily, setAvgDaily] = useState(0);
  const [topProducts, setTopProducts] = useState<any[]>([]);
  const [lowStockCount, setLowStockCount] = useState(0);
  const [topCities, setTopCities] = useState<any[]>([]);

  useEffect(() => {
    fetchAnalytics();
  }, []);

  const fetchAnalytics = async () => {
    setLoading(true);

    try {
       // 1. Orders for Revenue and Cities
       const { data: orders } = await supabase.from("orders").select("total, created_at, delivery_address, status");
       
       let rev = 0;
       let firstDate = new Date();
       let cityCounts: Record<string, number> = {};

       if (orders && orders.length > 0) {
          orders.forEach(o => {
             if (o.status !== "CANCELLED" && o.status !== "RETURNED") {
                rev += o.total || 0;
             }
             const d = new Date(o.created_at);
             if (d < firstDate) firstDate = d;

             if (o.delivery_address && o.delivery_address.city) {
                const c = o.delivery_address.city;
                cityCounts[c] = (cityCounts[c] || 0) + 1;
             }
          });
       }
       
       setTotalRevenue(rev);
       
       const days = Math.max(1, (new Date().getTime() - firstDate.getTime()) / (1000 * 60 * 60 * 24));
       setAvgDaily(rev / days);

       const sortedCities = Object.entries(cityCounts)
          .sort((a,b) => b[1] - a[1])
          .slice(0, 3)
          .map(([name, count]) => ({ name, count }));
       setTopCities(sortedCities);

       // 2. Order Items for Top Products
       const { data: orderItems } = await supabase.from("order_items").select("quantity, product_id, products(name)");
       let productCounts: Record<string, {name: string, units: number}> = {};
       
       if (orderItems) {
          orderItems.forEach(item => {
             const pid = item.product_id;
             if (!productCounts[pid]) {
                const prod = item.products as any;
                const prodName = Array.isArray(prod) ? prod[0]?.name : prod?.name;
                productCounts[pid] = { name: prodName || "Unknown", units: 0 };
             }
             productCounts[pid].units += item.quantity || 0;
          });
       }

       const sortedProducts = Object.values(productCounts).sort((a,b) => b.units - a.units).slice(0, 4);
       const maxUnits = sortedProducts[0]?.units || 1;
       setTopProducts(sortedProducts.map(p => ({
          ...p,
          percent: Math.min(100, Math.round((p.units / maxUnits) * 100))
       })));

       // 3. Low Stock products
       const { count: lowStock } = await supabase.from("products").select("id", { count: "exact", head: true }).lt("stock_quantity", 10);
       setLowStockCount(lowStock || 0);

    } catch (e) {
       console.error("Error fetching analytics", e);
    }

    setLoading(false);
  };

  return (
    <>
      <header className="sticky top-0 w-full z-40 bg-white/80 backdrop-blur-xl border-b border-slate-100 flex justify-between items-center h-16 px-8">
        <div className="flex items-center gap-4 flex-1">
          <div className="relative w-full max-w-md">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="lucide lucide-search absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <input
              type="text"
              placeholder="Search analytics, reports..."
              className="w-full bg-slate-50 border-none rounded-xl py-2 pl-9 pr-4 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all placeholder:text-slate-400"
            />
          </div>
        </div>
        <div className="flex items-center gap-3">
           <div className="w-8 h-8 rounded-full bg-indigo-100 border border-indigo-200 flex items-center justify-center text-indigo-700 text-xs font-bold">A</div>
        </div>
      </header>

      <main className="p-8 bg-surface min-h-screen">
        {/* Header */}
        <div className="flex items-end justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold tracking-tight text-on-surface">
              Analytics Overview
            </h1>
            <p className="text-on-surface-variant mt-1">
              Detailed performance metrics for your storefront
            </p>
          </div>
          <div className="flex gap-3">
            <button className="bg-surface-container-highest px-4 py-2.5 rounded-xl text-sm font-semibold flex items-center gap-2 hover:bg-slate-200 transition-colors">
              <Download size={18} />
              Export Report
            </button>
            <button onClick={fetchAnalytics} className="bg-gradient-to-br from-primary to-primary-container px-6 py-2.5 rounded-xl text-sm font-semibold text-white shadow-lg shadow-indigo-200 transition-all hover:shadow-indigo-300">
              Update Insights
            </button>
          </div>
        </div>

        {/* Bento Grid */}
        <div className="grid grid-cols-12 gap-6">
          {/* Revenue Line Chart */}
          <div className="col-span-12 lg:col-span-8 bg-surface-container-lowest rounded-xl shadow-sm border border-outline-variant/10 p-6 flex flex-col">
            <div className="flex justify-between items-center mb-8">
              <div>
                <p className="text-xs font-bold text-primary uppercase tracking-widest mb-1">
                  Financials
                </p>
                <h3 className="text-xl font-semibold text-on-surface">
                  Revenue Growth
                </h3>
              </div>
              <div className="flex bg-surface-container-low p-1 rounded-lg">
                <button className="px-4 py-1.5 text-xs font-semibold bg-white rounded-md shadow-sm">
                  All Time
                </button>
                <button disabled className="px-4 py-1.5 text-xs font-semibold text-on-surface-variant opacity-50">
                  Monthly
                </button>
              </div>
            </div>
            {/* Hardcoded chart purely for visual flair */}
            <div className="flex-1 flex items-end gap-2 h-56 relative group">
              <div className="absolute inset-0">
                <svg className="w-full h-full" viewBox="0 0 800 200" preserveAspectRatio="none">
                  <defs>
                    <linearGradient id="line-grad" x1="0" x2="0" y1="0" y2="1">
                      <stop offset="0%" stopColor="#233a87" stopOpacity="0.2" />
                      <stop offset="100%" stopColor="#233a87" stopOpacity="0" />
                    </linearGradient>
                  </defs>
                  <path
                    d="M0,180 Q100,160 200,100 T400,120 T600,40 T800,60"
                    fill="transparent"
                    stroke="#233a87"
                    strokeLinecap="round"
                    strokeWidth="3"
                  />
                  <path
                    d="M0,180 Q100,160 200,100 T400,120 T600,40 T800,60 V200 H0 Z"
                    fill="url(#line-grad)"
                  />
                </svg>
              </div>
              <div className="absolute top-10 right-[10%] bg-primary text-white text-[10px] px-2 py-1 rounded opacity-0 group-hover:opacity-100 transition-opacity">
                ₹{totalRevenue.toFixed(2)}
              </div>
            </div>
            <div className="flex justify-between mt-6 pt-6 border-t border-slate-50">
              <div className="flex flex-wrap items-center gap-6">
                <div>
                  <p className="text-[10px] font-bold text-on-surface-variant uppercase tracking-wider">
                    Avg. Daily Revenue
                  </p>
                  <p className="text-lg font-bold text-on-surface">₹{loading ? "..." : avgDaily.toFixed(2)}</p>
                </div>
                <div className="h-8 w-px bg-slate-100" />
                <div>
                  <p className="text-[10px] font-bold text-on-surface-variant uppercase tracking-wider">
                    Total Lifetime Revenue
                  </p>
                  <p className="text-lg font-bold text-secondary-fixed-dim">
                    ₹{loading ? "..." : totalRevenue.toFixed(2)}
                  </p>
                </div>
              </div>
              <span className="inline-flex items-center gap-1 text-[10px] font-bold text-green-600 bg-green-50 px-2 py-1 rounded-full whitespace-nowrap h-fit">
                <TrendingUp size={12} />
                +12.4%
              </span>
            </div>
          </div>

          {/* User Acquisition (Mock UI, minimal change) */}
          <div className="col-span-12 lg:col-span-4 bg-surface-container-lowest rounded-xl shadow-sm border border-outline-variant/10 p-6">
            <p className="text-xs font-bold text-secondary uppercase tracking-widest mb-1">
              Engagement
            </p>
            <h3 className="text-xl font-semibold mb-6 text-on-surface">
              User Acquisition
            </h3>
            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="text-3xl font-bold text-on-surface">12.5k</h4>
                  <p className="text-xs text-on-surface-variant">
                    New customers this month
                  </p>
                </div>
                <div className="w-20 h-10">
                  <svg className="w-full h-full" viewBox="0 0 100 40">
                    <path
                      d="M0,35 Q25,30 50,15 T100,10"
                      fill="transparent"
                      stroke="#fccc38"
                      strokeLinecap="round"
                      strokeWidth="2"
                    />
                  </svg>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-surface-container-low p-4 rounded-xl">
                  <p className="text-[10px] font-bold text-on-surface-variant uppercase">
                    Conversion
                  </p>
                  <p className="text-lg font-bold text-on-surface">3.8%</p>
                </div>
                <div className="bg-surface-container-low p-4 rounded-xl">
                  <p className="text-[10px] font-bold text-on-surface-variant uppercase">
                    Retention
                  </p>
                  <p className="text-lg font-bold text-on-surface">84%</p>
                </div>
              </div>
              <div className="pt-4 border-t border-slate-50 space-y-2">
                {["New", "Returning", "Churned"].map((s, i) => (
                  <div key={s} className="flex items-center gap-2">
                    <div
                      className={`w-2 h-2 rounded-full ${
                        i === 0
                          ? "bg-primary"
                          : i === 1
                          ? "bg-secondary"
                          : "bg-red-400"
                      }`}
                    />
                    <span className="text-xs text-on-surface-variant">{s}</span>
                    <div className="flex-1 h-1.5 bg-surface-container-low rounded-full overflow-hidden">
                      <div
                        className={`h-full rounded-full ${
                          i === 0
                            ? "bg-primary"
                            : i === 1
                            ? "bg-secondary"
                            : "bg-red-400"
                        }`}
                        style={{ width: i === 0 ? "65%" : i === 1 ? "25%" : "10%" }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Top Products */}
          <div className="col-span-12 lg:col-span-5 bg-surface-container-lowest rounded-xl shadow-sm border border-outline-variant/10 p-6">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-lg font-semibold text-on-surface">
                Top Performing Products
              </h3>
              <button className="p-1 text-slate-400 hover:text-on-surface rounded-lg">
                <MoreVertical size={16} />
              </button>
            </div>
            <div className="space-y-4">
              {loading ? (
                 <div className="animate-pulse space-y-4">
                    {[1,2,3,4].map(i => <div key={i} className="h-10 bg-slate-100 rounded-lg"></div>)}
                 </div>
              ) : topProducts.length === 0 ? (
                 <div className="text-sm text-slate-500 py-4">No product data available yet.</div>
              ) : (
                 topProducts.map((p) => (
                   <div key={p.name} className="space-y-2">
                     <div className="flex justify-between text-xs font-semibold text-on-surface">
                       <span className="line-clamp-1 pr-4">{p.name}</span>
                       <span className="shrink-0">{p.units} units</span>
                     </div>
                     <div className="h-2 w-full bg-slate-50 rounded-full overflow-hidden">
                       <div
                         className="h-full bg-primary rounded-full"
                         style={{ width: `${p.percent}%` }}
                       />
                     </div>
                   </div>
                 ))
              )}
            </div>
            <button className="w-full mt-8 py-3 bg-surface-container-low text-xs font-bold text-primary uppercase tracking-widest rounded-xl hover:bg-slate-100 transition-colors">
              View Product Analytics
            </button>
          </div>

          {/* Global Distribution */}
          <div className="col-span-12 lg:col-span-7 bg-surface-container-lowest rounded-xl shadow-sm border border-outline-variant/10 p-6">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h3 className="text-lg font-semibold text-on-surface">
                  Delivery Distribution
                </h3>
                <p className="text-xs text-on-surface-variant">
                  Orders heatmap by major city
                </p>
              </div>
              <div className="flex items-center gap-2 text-xs font-medium text-on-surface-variant">
                <span className="w-3 h-3 rounded-full bg-indigo-100" />
                <span>Low</span>
                <span className="w-12 h-2 rounded-full bg-gradient-to-r from-indigo-100 to-primary" />
                <span>High</span>
              </div>
            </div>
            {/* World Map Mockup with data overlay */}
            <div className="relative rounded-xl overflow-hidden h-[200px] bg-slate-100">
              <div
                className="absolute inset-0 opacity-30"
                style={{
                  backgroundImage: `radial-gradient(ellipse at 30% 50%, rgba(35,58,135,0.3) 0%, transparent 50%), 
                                   radial-gradient(ellipse at 70% 40%, rgba(35,58,135,0.4) 0%, transparent 40%),
                                   radial-gradient(ellipse at 55% 55%, rgba(35,58,135,0.2) 0%, transparent 30%)`,
                }}
              />
              <div className="absolute top-[25%] left-[22%] w-10 h-10 bg-primary/40 rounded-full blur-xl animate-pulse" />
              <div className="absolute top-[35%] left-[75%] w-12 h-12 bg-primary/50 rounded-full blur-xl animate-pulse" />
              <div className="absolute top-[45%] left-[48%] w-8 h-8 bg-primary/30 rounded-full blur-xl" />
              <div className="absolute top-[32%] left-[30%] md:left-[78%] bg-white/90 p-2 rounded-lg shadow-lg border border-slate-100 min-w-[120px]">
                {loading ? (
                   <div className="animate-pulse flex flex-col gap-1">
                      <div className="h-3 w-20 bg-slate-200 rounded"></div>
                      <div className="h-4 w-16 bg-slate-200 rounded"></div>
                   </div>
                ) : topCities.length > 0 ? (
                   <>
                      <p className="text-[10px] font-bold text-on-surface line-clamp-1">{topCities[0].name}</p>
                      <p className="text-xs font-bold text-primary">{topCities[0].count} Orders</p>
                   </>
                ) : (
                   <p className="text-xs text-slate-500">No data</p>
                )}
              </div>
            </div>
            <div className="mt-6 flex justify-between items-center">
              <div className="flex items-center gap-2">
                {topCities.slice(0, 3).map((c) => (
                  <div
                    key={c.name}
                    className="w-7 h-7 rounded-full border-2 border-white bg-indigo-100 flex items-center justify-center text-[9px] font-bold text-indigo-700 -ml-1 flex-shrink-0 ring-1 ring-slate-100 overflow-hidden"
                    title={c.name}
                  >
                    {c.name.substring(0,2).toUpperCase()}
                  </div>
                ))}
                
                <p className="text-[10px] text-on-surface-variant font-medium ml-1">
                  Recently active in these regions
                </p>
              </div>
              <a
                href="#"
                className="text-[10px] font-bold text-primary uppercase tracking-widest flex items-center gap-1 hover:underline"
              >
                Market Trends
                <ArrowUpRight size={12} />
              </a>
            </div>
          </div>

          {/* Inventory Warning */}
          {lowStockCount > 0 && (
             <div className="col-span-12 bg-gradient-to-r from-red-50 to-red-100 border border-red-200 p-4 rounded-xl flex items-center justify-between shadow-sm">
               <div className="flex items-center gap-4">
                 <div className="bg-white p-2 rounded-lg text-red-500 shadow-sm">
                   <span className="text-xl">⚠️</span>
                 </div>
                 <div>
                   <h4 className="font-bold text-red-900">
                     Inventory Warning
                   </h4>
                   <p className="text-sm text-red-800/80">
                     {lowStockCount} {lowStockCount === 1 ? 'product is' : 'products are'} reaching critical stock levels (&lt; 10 units). Review implementations.
                   </p>
                 </div>
               </div>
               <a href="/products" className="bg-red-600 text-white px-6 py-2 rounded-lg text-sm font-bold transition-transform hover:bg-red-700 hover:scale-105 active:scale-95">
                 Manage Stock
               </a>
             </div>
          )}
        </div>
      </main>
    </>
  );
}
