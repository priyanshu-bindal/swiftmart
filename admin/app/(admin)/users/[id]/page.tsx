"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase/client";
import { MapPin, ShoppingBag, DollarSign, Tag, TrendingUp, ChevronRight, Activity, ArrowLeft, RefreshCw } from "lucide-react";
import toast from "react-hot-toast";
import { format } from "date-fns";

export default function UserDetailsPage() {
  const router = useRouter();
  const params = useParams();
  const userId = params.id as string;

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [profile, setProfile] = useState<any>({});
  const [orders, setOrders] = useState<any[]>([]);
  const [orderItems, setOrderItems] = useState<any[]>([]);
  const [products, setProducts] = useState<any[]>([]);
  const [coupons, setCoupons] = useState<any[]>([]);
  const [flashDeals, setFlashDeals] = useState<any[]>([]);
  const [dbCoupons, setDbCoupons] = useState<any[]>([]);

  const [activeTab, setActiveTab] = useState("Orders");

  useEffect(() => {
    if (userId) fetchUserData();
  }, [userId]);

  const fetchUserData = async () => {
    setLoading(true);
    setError(null);
    try {
      // Parallel root level fetches
      const pProfile = supabase.from('profiles').select('*').eq('id', userId).single();
      const pOrders = supabase.from('orders').select('id, coupon_code, discount_amount, total, subtotal, status, created_at, delivery_address').eq('user_id', userId).order('created_at', { ascending: false });
      const pCoupons = supabase.from('coupons').select('code, discount_type, discount_value, valid_to, is_active');
      const pFlashDeals = supabase.from('flash_deal_products').select('product_id, override_price, flash_deals(id, title, discount_percent, start_time, end_time)');

      const [resProfile, resOrders, resCoupons, resFlashDeals] = await Promise.all([pProfile, pOrders, pCoupons, pFlashDeals]);

      if (resProfile.error) throw resProfile.error;
      if (resProfile.data) setProfile(resProfile.data);
      if (resOrders.data) setOrders(resOrders.data);
      if (resCoupons.data) setDbCoupons(resCoupons.data);
      if (resFlashDeals.data) setFlashDeals(resFlashDeals.data);

      let fetchedOrderItems: any[] = [];
      if (resOrders.data && resOrders.data.length > 0) {
        const orderIds = resOrders.data.map((o: any) => o.id);
        const { data: oiData, error: oiError } = await supabase.from('order_items').select('product_id, name, unit_price, quantity, total_price, created_at, order_id').in('order_id', orderIds);
        if (oiError) throw oiError;
        if (oiData) {
           fetchedOrderItems = oiData;
           setOrderItems(oiData);
        }
      }

      // Fetch products for analytics and general info just in case
      if (fetchedOrderItems.length > 0) {
        const productIds = fetchedOrderItems.map(i => i.product_id);
        const { data: prData } = await supabase.from('products').select('id, name, category_id, categories(name)').in('id', productIds);
        if (prData) setProducts(prData);
      }

    } catch (e: any) {
      console.error(e);
      setError(e.message || "Failed to load user data");
      toast.error("Failed to load user data");
    } finally {
      setLoading(false);
    }
  };

  const handleBlockUser = async () => {
    const newBlockedState = !profile.is_blocked;
    const confirmed = window.confirm(
      newBlockedState 
        ? 'Block this user? They will not be able to place orders.'
        : 'Unblock this user?'
    );
    if (!confirmed) return;

    const toastId = toast.loading("Updating status...");
    const { error } = await supabase
      .from('profiles')
      .update({ is_blocked: newBlockedState })
      .eq('id', userId);

    if (!error) {
      setProfile({...profile, is_blocked: newBlockedState});
      toast.success(newBlockedState ? 'User blocked.' : 'User unblocked.', {id: toastId});
    } else {
      toast.error('Operation failed: ' + error.message, {id: toastId});
    }
  };

  // Computations
  const totalOrders = orders.length;
  const totalSpend = orders.filter(o => o.status !== 'CANCELLED' && o.status !== 'RETURNED').reduce((sum, o) => sum + (o.total || 0), 0);
  const totalSavings = orders.filter(o => o.status !== 'CANCELLED' && o.status !== 'RETURNED').reduce((sum, o) => sum + (o.discount_amount || 0), 0);
  const avgOrderValue = totalOrders > 0 ? totalSpend / totalOrders : 0;

  const categoryCount: Record<string, number> = {};
  orderItems.forEach(item => {
    const product = products.find(p => p.id === item.product_id);
    const pCat = product?.categories as any;
    const catName = Array.isArray(pCat) ? pCat[0]?.name : pCat?.name;
    const finalName = catName || 'Others';
    categoryCount[finalName] = (categoryCount[finalName] || 0) + item.quantity;
  });

  const totalItems = Object.values(categoryCount).reduce((a, b) => a + b, 0);
  const categoryFrequency = Object.entries(categoryCount)
    .map(([name, count]) => ({
      name,
      percent: Math.round((count / (totalItems || 1)) * 100)
    }))
    .sort((a, b) => b.percent - a.percent)
    .slice(0, 5);

  const topCategory = categoryFrequency[0]?.name || 'N/A';
  const topCategoryPercent = categoryFrequency[0]?.percent || 0;

  const addresses = orders.map(o => {
    try {
      return typeof o.delivery_address === 'string'
        ? JSON.parse(o.delivery_address)
        : o.delivery_address;
    } catch { return null; }
  }).filter(Boolean);

  const uniqueAddresses = addresses.filter((addr, index, self) =>
    addr && index === self.findIndex(a => a?.address === addr?.address && a?.city === addr?.city)
  );

  const formatDateFallback = (dateStr: string) => {
    if (!dateStr) return "N/A";
    try {
      return format(new Date(dateStr), 'MMM dd, yyyy');
    } catch {
      return new Date(dateStr).toLocaleDateString('en-US', {
        month: 'short', day: 'numeric', year: 'numeric'
      });
    }
  };

  const getStatusColor = (s: string) => {
    switch (s?.toUpperCase()) {
       case 'DELIVERED': return 'bg-emerald-500';
       case 'OUT_FOR_DELIVERY': return 'bg-purple-500';
       case 'CANCELLED': return 'bg-red-500';
       default: return 'bg-blue-500'; // CONFIRMED etc
    }
  };
  
  const getStatusColorText = (s: string) => {
    switch (s?.toUpperCase()) {
       case 'DELIVERED': return 'text-emerald-700 bg-emerald-50 border-emerald-200';
       case 'OUT_FOR_DELIVERY': return 'text-purple-700 bg-purple-50 border-purple-200';
       case 'CANCELLED': return 'text-red-700 bg-red-50 border-red-200';
       default: return 'text-blue-700 bg-blue-50 border-blue-200';
    }
  };

  const getStatusLabel = (s: string) => {
     if (!s) return "Unknown";
     return s.replace(/_/g, ' ').replace(/\w\S*/g, (t) => t.charAt(0).toUpperCase() + t.substring(1).toLowerCase());
  };

  const isBlocked = profile?.is_blocked || false;
  const isRecentlyActive = orders.length > 0 && (new Date().getTime() - new Date(orders[0].created_at).getTime() < 30 * 24 * 60 * 60 * 1000);

  const usedCoupons = orders.filter(o => o.coupon_code && o.coupon_code.trim() !== '');

  const usedFlashDealsMap = new Map();
  
  orderItems.forEach(item => {
     const fdp = flashDeals.find(f => f.product_id === item.product_id);
     if (!fdp) return;
     
     if (item.unit_price <= fdp.override_price + 1) {
        const fd = Array.isArray(fdp.flash_deals) ? fdp.flash_deals[0] : fdp.flash_deals;
        if (!fd) return;
        
        const dedupKey = `${item.product_id}_${item.order_id}`;
        if (!usedFlashDealsMap.has(dedupKey)) {
           usedFlashDealsMap.set(dedupKey, {
              productName: item.name || 'Unknown',
              dealTitle: fd.title || 'Flash Deal',
              discountPercent: fd.discount_percent || 0,
              quantity: item.quantity,
              purchasedAt: item.created_at || '1970-01-01',
              savedAmount: Math.max(0, (fdp.override_price - item.unit_price) * item.quantity),
              orderId: item.order_id || 'UNKNOWN'
           });
        }
     }
  });

  const usedFlashDeals = Array.from(usedFlashDealsMap.values());

  const tabs = ["Orders", "Coupons", "Flash Deals", "Addresses", "Activity"];

  if (error) {
     return (
       <div className="flex h-screen items-center justify-center bg-[#f8f9fc]">
         <div className="text-center">
            <h3 className="text-xl font-bold text-gray-900 mb-2">Error loading user</h3>
            <p className="text-red-500 mb-6">{error}</p>
            <button onClick={fetchUserData} className="px-5 py-2.5 bg-gray-900 text-white rounded-xl font-bold hover:bg-gray-800 flex items-center gap-2 mx-auto">
               <RefreshCw size={16} /> Retry
            </button>
         </div>
       </div>
     );
  }

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center bg-[#f8f9fc]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#f8f9fc]">
      {/* Header */}
      <header className="sticky top-0 w-full z-40 bg-white/80 backdrop-blur-xl border-b border-gray-200 px-8 py-4">
       

        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
             <button onClick={() => router.back()} className="p-2 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"><ArrowLeft size={20} className="text-gray-700" /></button>
             <h1 className="text-3xl font-bold text-gray-900 tracking-tight">User Details</h1>
          </div>
          <div className="flex items-center gap-3">
            <button 
              onClick={handleBlockUser}
              className={`px-5 py-2.5 rounded-xl text-sm font-bold transition-all shadow-sm ${
                 isBlocked 
                 ? "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50" 
                 : "bg-red-50 text-red-600 border border-red-200 hover:bg-red-100"
              }`}
            >
              {isBlocked ? '✓ Unblock User' : 'Block User'}
            </button>
            <button 
              onClick={() => router.push(`/orders?user=${userId}`)}
              className="px-5 py-2.5 rounded-xl bg-indigo-600 text-white text-sm font-bold shadow-lg shadow-indigo-600/20 hover:bg-indigo-700 transition-all hover:shadow-indigo-600/40"
            >
              View All Orders
            </button>
          </div>
        </div>
      </header>

      <main className="p-8 max-w-7xl mx-auto">
         <div className="flex flex-col lg:flex-row gap-6 items-start">
            
            {/* LEFT COLUMN - Profile & Stats */}
            <div className="w-full lg:w-[320px] flex flex-col gap-6 shrink-0">
               
               {/* Profile Card */}
               <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6 flex flex-col items-center">
                  <div className="relative mb-4">
                     {profile?.avatar_url ? (
                        <img src={profile.avatar_url} className="w-24 h-24 rounded-full object-cover border-4 border-white shadow-md" alt="Avatar" />
                     ) : (
                        <div className="w-24 h-24 rounded-full bg-indigo-100 border-4 border-white shadow-md flex items-center justify-center text-indigo-700 text-2xl font-bold">
                           {profile?.full_name?.[0]?.toUpperCase() || 'U'}
                        </div>
                     )}
                     <div className={`absolute bottom-1 right-2 w-4 h-4 rounded-full border-2 border-white shadow-sm ${isRecentlyActive ? 'bg-green-500' : 'bg-gray-400'}`} />
                  </div>
                  
                  <h2 className="text-xl font-bold text-gray-900 text-center line-clamp-1">{profile?.full_name || 'Unknown User'}</h2>
                  <p className="text-sm text-gray-500 mb-6">{profile?.email}</p>

                  <div className="flex items-center justify-center gap-2 mb-6 w-full">
                     <span className={`px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider border ${isBlocked ? 'bg-red-50 text-red-700 border-red-200' : 'bg-green-50 text-green-700 border-green-200'}`}>
                        {isBlocked ? 'BLOCKED' : 'ACTIVE'}
                     </span>
                     <span className="px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider bg-gray-100 text-gray-700 border border-gray-200">
                        {profile?.role || 'CUSTOMER'}
                     </span>
                  </div>

                  <div className="w-full bg-gray-50 rounded-xl p-4 space-y-3 border border-gray-100">
                     <div className="flex justify-between items-center text-sm">
                        <span className="text-gray-500 font-medium tracking-wide">Phone</span>
                        <span className="text-gray-900 font-bold">{profile?.phone || 'Not provided'}</span>
                     </div>
                     <div className="flex justify-between items-center text-sm">
                        <span className="text-gray-500 font-medium tracking-wide">Member Since</span>
                        <span className="text-gray-900 font-bold">
                           {profile?.created_at ? new Date(profile.created_at).toLocaleDateString('en-IN', { month: 'short', year: 'numeric' }) : 'N/A'}
                        </span>
                     </div>
                  </div>
               </div>

               {/* Stats Cards */}
               <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6 flex items-center justify-between hover:shadow-md transition-shadow group">
                  <div>
                     <p className="text-[11px] font-bold text-gray-500 uppercase tracking-widest mb-1">Total Orders</p>
                     <p className="text-2xl font-black text-indigo-600">{totalOrders}</p>
                  </div>
                  <div className="w-12 h-12 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center group-hover:scale-110 transition-transform"><ShoppingBag size={24} /></div>
               </div>

               <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6 flex items-center justify-between hover:shadow-md transition-shadow group">
                  <div>
                     <p className="text-[11px] font-bold text-gray-500 uppercase tracking-widest mb-1">Total Spend</p>
                     <p className="text-2xl font-black text-emerald-600">₹{totalSpend.toFixed(2)}</p>
                  </div>
                  <div className="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center group-hover:scale-110 transition-transform"><DollarSign size={24} /></div>
               </div>

               <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6 flex items-center justify-between hover:shadow-md transition-shadow group">
                  <div>
                     <p className="text-[11px] font-bold text-gray-500 uppercase tracking-widest mb-1">Total Savings</p>
                     <p className="text-2xl font-black text-red-600">₹{totalSavings.toFixed(2)}</p>
                  </div>
                  <div className="w-12 h-12 rounded-xl bg-red-50 text-red-600 flex items-center justify-center group-hover:scale-110 transition-transform"><Tag size={24} /></div>
               </div>

            </div>

            {/* RIGHT COLUMN - Tabs */}
            <div className="flex-1 flex flex-col min-w-0">
               {/* Tab Headers */}
               <div className="flex overflow-x-auto no-scrollbar gap-2 mb-6">
                  {tabs.map(tab => (
                     <button
                        key={tab}
                        onClick={() => setActiveTab(tab)}
                        className={`px-6 py-3 whitespace-nowrap rounded-xl text-sm font-bold transition-all border ${
                           activeTab === tab 
                           ? "bg-white text-indigo-600 border-indigo-200 shadow-sm" 
                           : "bg-transparent text-gray-500 border-transparent hover:bg-white hover:border-gray-200"
                        }`}
                     >
                        {tab}
                     </button>
                  ))}
               </div>

               {/* Tab Contents */}
               {activeTab === "Orders" && (
                  <div className="space-y-6">
                     <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200">
                           <p className="text-[11px] font-bold text-gray-500 uppercase tracking-widest mb-1">Most Ordered Category</p>
                           <div className="flex items-end gap-2 mb-6">
                              <h3 className="text-2xl font-black text-gray-900 h-8 line-clamp-1">{topCategory}</h3>
                              <span className="text-xl font-bold text-indigo-600 h-8">{topCategoryPercent}%</span>
                           </div>
                           <p className="text-[11px] font-bold text-gray-500 uppercase tracking-widest mb-1 mt-2">Avg. Order Value</p>
                           <div className="flex items-center gap-2">
                              <span className="text-xl font-bold text-emerald-600">₹{avgOrderValue.toFixed(2)}</span>
                              <TrendingUp size={16} className="text-emerald-500" />
                           </div>
                        </div>

                        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200 flex flex-col justify-center">
                           <p className="text-[11px] font-bold text-gray-500 uppercase tracking-widest mb-4">Category Frequency</p>
                           <div className="space-y-4">
                              {categoryFrequency.length === 0 ? (
                                 <p className="text-sm text-gray-400">Not enough data.</p>
                              ) : categoryFrequency.map((cat, i) => (
                                 <div key={cat.name} className="flex items-center gap-3">
                                    <span className="text-xs font-bold text-gray-700 w-24 truncate">{cat.name.toUpperCase()}</span>
                                    <div className="flex-1 h-1.5 bg-gray-100 rounded-full overflow-hidden">
                                       <div 
                                          className="h-full rounded-full transition-all duration-700 ease-in-out" 
                                          style={{ 
                                             width: `${cat.percent}%`,
                                             backgroundColor: i === 0 ? '#4f46e5' : i === 1 ? '#059669' : '#94a3b8'
                                          }} 
                                       />
                                    </div>
                                    <span className="text-xs font-bold text-gray-500 w-8 text-right">{cat.percent}%</span>
                                 </div>
                              ))}
                           </div>
                        </div>
                     </div>

                     <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden">
                        <div className="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50">
                           <h3 className="text-base font-bold text-gray-900">Recent Orders</h3>
                           <button onClick={() => router.push(`/orders?user=${userId}`)} className="text-xs font-bold text-indigo-600 uppercase tracking-wider hover:underline flex items-center gap-1">VIEW ALL <ChevronRight size={14}/></button>
                        </div>
                        <div className="overflow-x-auto">
                           <table className="w-full text-left border-collapse">
                              <thead>
                                 <tr className="border-b border-gray-100">
                                    <th className="px-6 py-4 text-[11px] font-bold text-gray-500 uppercase tracking-wider">ORDER ID</th>
                                    <th className="px-6 py-4 text-[11px] font-bold text-gray-500 uppercase tracking-wider">DATE</th>
                                    <th className="px-6 py-4 text-[11px] font-bold text-gray-500 uppercase tracking-wider">STATUS</th>
                                    <th className="px-6 py-4 text-[11px] font-bold text-gray-500 uppercase tracking-wider text-right">AMOUNT</th>
                                 </tr>
                              </thead>
                              <tbody>
                                 {orders.length === 0 ? (
                                    <tr><td colSpan={4} className="text-center py-8 text-sm text-gray-500">No orders yet.</td></tr>
                                 ) : orders.slice(0, 8).map(order => (
                                    <tr 
                                       key={order.id} 
                                       onClick={() => router.push(`/orders/${order.id}`)}
                                       className="group cursor-pointer border-b border-gray-50 hover:bg-gray-50 transition-colors last:border-0"
                                    >
                                       <td className="px-6 py-4">
                                          <span className="text-sm font-bold text-indigo-600 group-hover:underline">#ORD-{order.id.substring(0,8).toUpperCase()}</span>
                                       </td>
                                       <td className="px-6 py-4 text-sm text-gray-600 font-medium">{formatDateFallback(order.created_at)}</td>
                                       <td className="px-6 py-4">
                                          <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold border ${getStatusColorText(order.status)}`}>
                                             <span className={`w-1.5 h-1.5 rounded-full mr-1.5 ${getStatusColor(order.status)}`} />
                                             {getStatusLabel(order.status)}
                                          </span>
                                       </td>
                                       <td className="px-6 py-4 text-sm font-bold text-gray-900 text-right">₹{(order.total || 0).toFixed(2)}</td>
                                    </tr>
                                 ))}
                              </tbody>
                           </table>
                        </div>
                     </div>
                  </div>
               )}

               {activeTab === "Coupons" && (
                  <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-8 text-center min-h-[300px] flex flex-col justify-center items-center">
                     {usedCoupons.length === 0 ? (
                        <>
                           <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center text-3xl mb-4 text-gray-400">🎟️</div>
                           <h3 className="text-lg font-bold text-gray-900 mb-1">No Coupons Used</h3>
                           <p className="text-sm text-gray-500 max-w-sm">This user hasn't redeemed any coupons yet. They will appear here once utilized.</p>
                        </>
                     ) : (
                        <div className="w-full h-full flex flex-col justify-start">
                           <h3 className="text-lg font-bold text-gray-900 mb-4 text-left">Applied Coupons</h3>
                           <div className="space-y-4">
                              {usedCoupons.map((order, i) => {
                                 const dbCoupon = dbCoupons.find(c => c.code.toLowerCase() === order.coupon_code.toLowerCase());
                                 return (
                                 <div key={i} className="bg-white rounded-xl p-4 flex justify-between items-center border border-gray-200 hover:border-gray-300 transition-colors shadow-sm">
                                    <div className="flex items-center gap-4">
                                       <div className="w-12 h-12 rounded-full bg-pink-50 text-pink-500 flex items-center justify-center shrink-0">
                                          {/* Ticket Icon */}
                                          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 7a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v3a2 2 0 0 0 0 4v3a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-3a2 2 0 0 0 0-4V7z"/><line x1="9" y1="9" x2="15" y2="15"/><line x1="15" y1="9" x2="9" y2="15"/></svg>
                                       </div>
                                       <div className="text-left">
                                          <div className="flex items-center gap-2 mb-1">
                                             <h4 className="text-base font-bold font-mono text-gray-900">{order.coupon_code}</h4>
                                             {dbCoupon && (
                                                <span className="px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider bg-pink-100 text-pink-700">
                                                   {dbCoupon.discount_type === 'percentage' || dbCoupon.discount_type === 'percent' ? `${dbCoupon.discount_value}% OFF` : `₹${dbCoupon.discount_value} OFF`}
                                                </span>
                                             )}
                                          </div>
                                          <p className="text-xs text-gray-500">
                                             Order #{order.id.substring(0,8).toUpperCase()} · {formatDateFallback(order.created_at)}
                                          </p>
                                          {dbCoupon?.valid_to && (
                                             <p className="text-[11px] text-gray-400 mt-1">
                                                Valid till {formatDateFallback(dbCoupon.valid_to)}
                                             </p>
                                          )}
                                       </div>
                                    </div>
                                    <div className="text-right flex flex-col items-end gap-1">
                                       <span className="text-sm font-bold tracking-wide text-emerald-600">
                                          -₹{(order.discount_amount || 0).toFixed(0)}
                                       </span>
                                       <span className={`inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider ${getStatusColorText(order.status)} mt-1`}>
                                          {getStatusLabel(order.status)}
                                       </span>
                                    </div>
                                 </div>
                                 );
                              })}
                           </div>
                        </div>
                     )}
                  </div>
               )}

               {activeTab === "Flash Deals" && (
                  <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-8 text-center min-h-[300px] flex flex-col justify-center items-center">
                     {usedFlashDeals.length === 0 ? (
                        <>
                           <div className="w-16 h-16 rounded-full bg-orange-100 flex items-center justify-center text-orange-500 mb-4"><Tag size={28} /></div>
                           <h3 className="text-lg font-bold text-gray-900 mb-1">No Flash Deals Found</h3>
                           <p className="text-sm text-gray-500 max-w-sm">This user hasn't successfully checked out any flash deals yet.</p>
                        </>
                     ) : (
                        <div className="w-full h-full flex flex-col justify-start text-left">
                           <h3 className="text-lg font-bold text-gray-900 mb-4">Redeemed Flash Deals</h3>
                           <div className="space-y-4">
                              {usedFlashDeals.map((fd: any, i: number) => (
                                 <div key={i} className="bg-white rounded-xl p-4 flex justify-between items-center border border-gray-200 hover:border-gray-300 transition-colors shadow-sm">
                                    <div className="flex items-center gap-4">
                                       <div className="w-12 h-12 rounded-full bg-orange-50 text-orange-600 flex items-center justify-center shrink-0">
                                          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/></svg>
                                       </div>
                                       <div>
                                          <div className="flex items-center gap-2 mb-1">
                                             <h4 className="text-base font-bold text-gray-900">{fd.productName}</h4>
                                             {fd.discountPercent > 0 && (
                                                <span className="px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider bg-orange-100 text-orange-700">
                                                   {fd.discountPercent.toFixed(0)}% OFF
                                                </span>
                                             )}
                                          </div>
                                          <p className="text-xs text-gray-500">
                                             {fd.dealTitle} · Qty: {fd.quantity} · {formatDateFallback(fd.purchasedAt)}
                                          </p>
                                       </div>
                                    </div>
                                    <div className="text-right flex flex-col items-end gap-1">
                                       <span className="text-sm font-bold tracking-wide text-emerald-600">
                                          Saved ₹{fd.savedAmount.toFixed(0)}
                                       </span>
                                    </div>
                                 </div>
                              ))}
                           </div>
                        </div>
                     )}
                  </div>
               )}

               {activeTab === "Addresses" && (
                  <div className="space-y-4">
                     {uniqueAddresses.length === 0 ? (
                        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-8 text-center flex flex-col justify-center items-center h-48">
                           <p className="text-sm text-gray-500 font-medium">No saved addresses on file.</p>
                        </div>
                     ) : uniqueAddresses.map((addr, i) => (
                        <div key={i} className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6 flex gap-4 items-start hover:border-gray-300 transition-colors">
                           <div className="w-10 h-10 rounded-full bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0"><MapPin size={20} /></div>
                           <div>
                              <p className="text-base font-bold text-gray-900 mb-1">{addr.address || 'Location Data'}</p>
                              {addr.city && <p className="text-sm text-gray-600">{addr.city}</p>}
                           </div>
                        </div>
                     ))}
                  </div>
               )}

               {activeTab === "Activity" && (
                  <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6 lg:p-8">
                     <h3 className="text-lg font-bold text-gray-900 mb-6">User Activity Timeline</h3>
                     {orders.length === 0 ? (
                        <p className="text-sm text-gray-500 text-center py-8">No activity recorded.</p>
                     ) : (
                        <div className="relative pl-6 space-y-8 border-l-2 border-gray-100 ml-4">
                           {orders.map((order, i) => (
                              <div key={order.id} className="relative">
                                 <div className={`absolute -left-[31px] w-4 h-4 rounded-full border-4 border-white ${getStatusColor(order.status)} shadow-sm`} />
                                 <div className="bg-gray-50 rounded-xl p-4 border border-gray-100 flex justify-between items-center sm:items-start flex-col sm:flex-row gap-2 hover:bg-gray-100 transition-colors">
                                    <div>
                                       <p className="text-sm font-bold text-gray-900">
                                          Order <span className="text-indigo-600">#{order.id.substring(0,8).toUpperCase()}</span> — 
                                          <span className="ml-1 text-gray-600">{getStatusLabel(order.status)}</span>
                                       </p>
                                       <p className="text-xs text-gray-500 font-medium mt-1">{formatDateFallback(order.created_at)}</p>

                                    </div>
                                    <span className="text-sm font-black text-gray-900 px-3 py-1 bg-white rounded-lg border border-gray-200 shadow-sm">
                                       ₹{order.total?.toFixed(2)}
                                    </span>
                                 </div>
                              </div>
                           ))}
                        </div>
                     )}
                  </div>
               )}
            </div>

         </div>
      </main>
    </div>
  );
}
