"use client";

import { Plus, Edit2, Trash2, Tag, X } from "lucide-react";
import { useEffect, useState, useMemo } from "react";
import { supabase } from "@/lib/supabase/client";
import toast from "react-hot-toast";

export default function CouponsPage() {
  const [coupons, setCoupons] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // Filters
  const [searchQuery, setSearchQuery] = useState("");

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [editingCouponId, setEditingCouponId] = useState<string | null>(null);
  
  // New Coupon Form
  const [newCoupon, setNewCoupon] = useState({
    code: "",
    discount_type: "percentage",
    discount_value: "",
    min_order_value: "",
    valid_from: "",
    valid_to: "",
    is_active: true,
  });

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    const { data: couponData } = await supabase
      .from("coupons")
      .select("*")
      .order("created_at", { ascending: false });

    if (couponData) setCoupons(couponData);
    setLoading(false);
  };

  const handleSaveCoupon = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    const loadingToast = toast.loading(editingCouponId ? "Updating coupon..." : "Creating coupon...");
    
    try {
      const payload = {
        code: newCoupon.code.toUpperCase(),
        discount_type: newCoupon.discount_type,
        discount_value: parseFloat(newCoupon.discount_value) || 0,
        min_order_value: parseFloat(newCoupon.min_order_value) || 0,
        valid_from: newCoupon.valid_from ? new Date(newCoupon.valid_from).toISOString() : null,
        valid_to: newCoupon.valid_to ? new Date(newCoupon.valid_to).toISOString() : null,
        is_active: newCoupon.is_active,
      };

      let error;
      if (editingCouponId) {
        const { error: updateError } = await supabase.from("coupons").update(payload).eq("id", editingCouponId);
        error = updateError;
      } else {
        const { error: insertError } = await supabase.from("coupons").insert([payload]);
        error = insertError;
      }

      if (error) throw error;
      
      toast.success(editingCouponId ? "Coupon updated!" : "Coupon created!", { id: loadingToast });
      setIsModalOpen(false);
      
      // Reset form
      setNewCoupon({
         code: "", discount_type: "percentage", discount_value: "", min_order_value: "", valid_from: "", valid_to: "", is_active: true
      });
      setEditingCouponId(null);
      fetchData();
    } catch (error: any) {
      toast.error(error.message || "An error occurred", { id: loadingToast });
    } finally {
      setIsSaving(false);
    }
  };

  const openEditModal = (coupon: any) => {
    setEditingCouponId(coupon.id);
    setNewCoupon({
      code: coupon.code || "",
      discount_type: coupon.discount_type || "percentage",
      discount_value: coupon.discount_value?.toString() || "",
      min_order_value: coupon.min_order_value?.toString() || "",
      valid_from: coupon.valid_from ? new Date(coupon.valid_from).toISOString().split('T')[0] : "",
      valid_to: coupon.valid_to ? new Date(coupon.valid_to).toISOString().split('T')[0] : "",
      is_active: coupon.is_active ?? true,
    });
    setIsModalOpen(true);
  };

  const toggleStatus = async (coupon: any) => {
    const loadingToast = toast.loading("Updating status...");
    const { error } = await supabase.from("coupons").update({ is_active: !coupon.is_active }).eq("id", coupon.id);
    if (error) {
      toast.error("Failed to update status", { id: loadingToast });
    } else {
      toast.success("Status updated", { id: loadingToast });
      fetchData();
    }
  };

  const filteredCoupons = useMemo(() => {
    let result = coupons;
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      result = result.filter(c => c.code.toLowerCase().includes(q));
    }
    return result;
  }, [coupons, searchQuery]);

  const activeCouponsCount = coupons.filter(c => c.is_active).length;
  const featured = coupons[0]; // Just take the newest one

  // Derived display formatting
  const formatDiscount = (type: string, val: number) => {
     if (type === "percentage") return `${val}% OFF`;
     if (type === "flat") return `₹${val} OFF`;
     return String(val);
  };

  const isExpired = (dateString: string | null) => {
     if (!dateString) return false;
     return new Date(dateString) < new Date();
  };

  return (
    <>
      <header className="sticky top-0 w-full z-40 bg-white/80 backdrop-blur-xl border-b border-slate-100 flex justify-between items-center h-16 px-8">
        <div className="flex items-center gap-4 flex-1">
          <div className="relative w-full max-w-md">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="lucide lucide-search absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <input
              type="text"
              placeholder="Search coupons..."
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
              Coupons & Cashback
            </h1>
            <p className="text-sm text-on-surface-variant mt-1">
              Create and manage discount codes and promotional offers.
            </p>
          </div>
          <button onClick={() => {
            setEditingCouponId(null);
            setNewCoupon({ code: "", discount_type: "percentage", discount_value: "", min_order_value: "", valid_from: "", valid_to: "", is_active: true });
            setIsModalOpen(true);
          }} className="bg-gradient-to-br from-primary to-primary-container text-white px-5 py-2.5 rounded-xl font-semibold flex items-center gap-2 shadow-lg shadow-indigo-500/10 hover:shadow-indigo-500/20 transition-all">
            <Plus size={18} />
            Create Coupon
          </button>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          {[
            { label: "Active Coupons", value: loading ? "..." : activeCouponsCount.toString(), color: "text-emerald-600" },
            { label: "Total Redemptions", value: "N/A", color: "text-on-surface" }, // Mock since no data
            { label: "Avg. Discount", value: "N/A", color: "text-primary" },
            { label: "Revenue Saved", value: "N/A", color: "text-secondary" },
          ].map(({ label, value, color }) => (
            <div
              key={label}
              className="bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-outline-variant/10"
            >
              <p className="text-xs font-bold text-on-surface-variant uppercase tracking-wider mb-2">
                {label}
              </p>
              <p className={`text-3xl font-bold ${color}`}>{value}</p>
            </div>
          ))}
        </div>

        {/* Coupon Preview Card */}
        {!loading && featured && (
           <div className="mb-8 bg-gradient-to-br from-primary to-primary-container rounded-2xl p-8 text-white relative overflow-hidden">
             <div className="absolute -top-10 -right-10 w-48 h-48 bg-white/5 rounded-full blur-3xl" />
             <div className="absolute -bottom-10 -left-10 w-48 h-48 bg-white/5 rounded-full blur-3xl" />
             <div className="relative flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
               <div>
                 <div className="flex items-center gap-3 mb-4">
                   <div className="bg-white/20 p-2 rounded-lg">
                     <Tag size={20} />
                   </div>
                   <span className="text-white/70 text-sm font-medium">
                     Latest active coupon
                   </span>
                 </div>
                 <h2 className="text-5xl font-black tracking-tight mb-2">
                   {featured.code}
                 </h2>
                 <p className="text-white/80 text-sm">
                   {formatDiscount(featured.discount_type, featured.discount_value)} on orders above ₹{featured.min_order_value} 
                   {featured.valid_to ? ` • Valid until ${new Date(featured.valid_to).toLocaleDateString()}` : ' • No Expiry'}
                 </p>
               </div>
             </div>
           </div>
        )}

        {/* Coupons Table */}
        <div className="bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm">
          <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <h3 className="font-bold text-on-surface">All Coupons</h3>
          </div>
          <div className="overflow-x-auto">
             <table className="w-full text-left">
               <thead className="bg-surface-container-low">
                 <tr>
                   {["Code", "Type", "Discount", "Min. Order", "Expiry", "Status", ""].map(
                     (h) => (
                       <th
                         key={h}
                         className="px-6 py-4 text-[11px] font-bold text-on-surface-variant uppercase tracking-wider"
                       >
                         {h}
                       </th>
                     )
                   )}
                 </tr>
               </thead>
               <tbody className="divide-y divide-slate-50">
                 {loading ? (
                    Array(3).fill(0).map((_, i) => (
                       <tr key={`sk-${i}`}>
                         <td className="px-6 py-4"><div className="h-6 w-24 bg-slate-200 animate-pulse rounded-lg" /></td>
                         <td className="px-6 py-4"><div className="h-4 w-16 bg-slate-200 animate-pulse rounded" /></td>
                         <td className="px-6 py-4"><div className="h-4 w-16 bg-slate-200 animate-pulse rounded" /></td>
                         <td className="px-6 py-4"><div className="h-4 w-16 bg-slate-200 animate-pulse rounded" /></td>
                         <td className="px-6 py-4"><div className="h-4 w-20 bg-slate-200 animate-pulse rounded" /></td>
                         <td className="px-6 py-4"><div className="h-5 w-16 bg-slate-200 animate-pulse rounded-full" /></td>
                         <td className="px-6 py-4"></td>
                       </tr>
                    ))
                 ) : filteredCoupons.length === 0 ? (
                    <tr><td colSpan={7} className="px-6 py-8 text-center text-sm text-slate-500">No coupons found.</td></tr>
                 ) : (
                    filteredCoupons.map((coupon) => {
                      const expired = isExpired(coupon.valid_to);
                      const statusLabel = expired ? "Expired" : (coupon.is_active ? "Active" : "Disabled");
                      const statusClass = 
                        statusLabel === "Active" ? "bg-emerald-100 text-emerald-700" :
                        statusLabel === "Expired" ? "bg-red-100 text-red-700" : "bg-slate-100 text-slate-600";

                      return (
                       <tr
                         key={coupon.id}
                         className="hover:bg-surface-container-low transition-colors group"
                       >
                         <td className="px-6 py-4">
                           <span className="font-mono font-bold text-primary text-sm bg-indigo-50 px-3 py-1 rounded-lg">
                             {coupon.code}
                           </span>
                         </td>
                         <td className="px-6 py-4 text-sm text-on-surface-variant capitalize">
                           {coupon.discount_type}
                         </td>
                         <td className="px-6 py-4 font-bold text-on-surface text-sm">
                           {formatDiscount(coupon.discount_type, coupon.discount_value)}
                         </td>
                         <td className="px-6 py-4 text-sm text-on-surface-variant">
                           ₹{(coupon.min_order_value || 0).toFixed(2)}
                         </td>
                         <td className="px-6 py-4 text-xs text-on-surface-variant">
                           {coupon.valid_to ? new Date(coupon.valid_to).toLocaleDateString() : "No Expiry"}
                         </td>
                         <td className="px-6 py-4">
                           <button
                             onClick={() => toggleStatus(coupon)}
                             className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider cursor-pointer hover:opacity-80 transition-opacity ${statusClass}`}
                           >
                             {statusLabel}
                           </button>
                         </td>
                         <td className="px-6 py-4">
                           <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                             <button onClick={() => openEditModal(coupon)} className="p-1.5 text-indigo-600 hover:bg-indigo-50 rounded-lg">
                               <Edit2 size={14} />
                             </button>
                             <button 
                                onClick={async () => {
                                   if(confirm("Delete coupon?")) {
                                      const loadingToast = toast.loading("Deleting coupon...");
                                      const { error } = await supabase.from("coupons").delete().eq("id", coupon.id);
                                      if (error) {
                                        toast.error("Failed to delete coupon", { id: loadingToast });
                                      } else {
                                        toast.success("Coupon deleted", { id: loadingToast });
                                        fetchData();
                                      }
                                   }
                                }}
                                className="p-1.5 text-error hover:bg-error-container/20 rounded-lg">
                               <Trash2 size={14} />
                             </button>
                           </div>
                         </td>
                       </tr>
                      );
                    })
                 )}
               </tbody>
             </table>
          </div>
        </div>

        {/* Add Coupon Modal */}
        {isModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" onClick={() => !isSaving && setIsModalOpen(false)}></div>
            <div className="bg-white rounded-[24px] shadow-2xl w-full max-w-2xl overflow-hidden relative z-10 animate-fade-in-up flex flex-col">
               {/* Header */}
               <div className="bg-[#6b46c1] px-8 py-6 relative">
                  <h3 className="text-2xl font-bold text-white mb-1">{editingCouponId ? "Edit Coupon" : "Create New Coupon"}</h3>
                  <p className="text-white/80 text-sm">Define the rules for your new promotional code</p>
                  <button onClick={() => setIsModalOpen(false)} disabled={isSaving} className="absolute right-6 top-6 bg-white/20 hover:bg-white/30 text-white p-2 rounded-full transition-colors flex items-center justify-center">
                     <X size={16} strokeWidth={3} />
                  </button>
               </div>
               
               <div className="px-8 py-8 overflow-y-auto max-h-[75vh]">
                 <form id="couponForm" onSubmit={handleSaveCoupon} className="space-y-6">
                    {/* Row 1 */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      <div>
                        <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Coupon Code</label>
                        <input required type="text" value={newCoupon.code} onChange={e => setNewCoupon({...newCoupon, code: e.target.value})} className="w-full px-5 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#6b46c1] outline-none font-medium placeholder:text-slate-400 uppercase" placeholder="e.g. WELCOME100" />
                      </div>
                      <div>
                        <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Internal Title</label>
                        <input type="text" className="w-full px-5 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#6b46c1] outline-none font-medium placeholder:text-slate-400" placeholder="e.g. Spring 2024 Promo" />
                      </div>
                    </div>

                    {/* Row 2 */}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                      <div>
                        <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Discount Type</label>
                        <div className="relative">
                          <select required value={newCoupon.discount_type} onChange={e => setNewCoupon({...newCoupon, discount_type: e.target.value})} className="w-full px-5 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#6b46c1] outline-none font-medium appearance-none">
                             <option value="percentage">Percentage (%)</option>
                             <option value="flat">Flat Amount</option>
                          </select>
                          <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m6 9 6 6 6-6"/></svg>
                          </div>
                        </div>
                      </div>
                      <div>
                        <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Value</label>
                        <div className="relative">
                          <input required type="number" step="0.01" value={newCoupon.discount_value} onChange={e => setNewCoupon({...newCoupon, discount_value: e.target.value})} className="w-full px-5 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#6b46c1] outline-none font-medium text-slate-800" placeholder="20" />
                          <span className="absolute right-5 top-1/2 -translate-y-1/2 font-bold text-slate-400">
                            {newCoupon.discount_type === 'percentage' ? '%' : '₹'}
                          </span>
                        </div>
                      </div>
                      <div>
                        <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Min. Spend</label>
                        <div className="relative">
                          <span className="absolute left-5 top-1/2 -translate-y-1/2 font-bold text-slate-400">₹</span>
                          <input required type="number" step="0.01" value={newCoupon.min_order_value} onChange={e => setNewCoupon({...newCoupon, min_order_value: e.target.value})} className="w-full pl-9 pr-5 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#6b46c1] outline-none font-medium text-slate-800" placeholder="50.00" />
                        </div>
                      </div>
                    </div>

                    {/* Row 3 */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      <div>
                        <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Start Date</label>
                        <input type="date" value={newCoupon.valid_from} onChange={e => setNewCoupon({...newCoupon, valid_from: e.target.value})} className="w-full px-5 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#6b46c1] outline-none font-medium text-slate-600" />
                      </div>
                      <div>
                        <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Expiry Date</label>
                        <input type="date" value={newCoupon.valid_to} onChange={e => setNewCoupon({...newCoupon, valid_to: e.target.value})} className="w-full px-5 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#6b46c1] outline-none font-medium text-slate-800" />
                      </div>
                    </div>

                    {/* Row 4 */}
                    <div>
                      <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Usage Limit</label>
                      <div className="flex items-center gap-4">
                         <input type="number" className="w-32 px-5 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#6b46c1] outline-none font-medium text-slate-800" placeholder="1000" />
                         <span className="text-sm font-medium text-slate-600">total redemptions. (Leave blank for unlimited)</span>
                      </div>
                    </div>

                    <div className="flex items-center gap-2 mt-4 hidden">
                       <input type="checkbox" id="isActive" checked={newCoupon.is_active} onChange={e => setNewCoupon({...newCoupon, is_active: e.target.checked})} className="rounded text-[#6b46c1] focus:ring-[#6b46c1] disabled:opacity-50" />
                       <label htmlFor="isActive" className="text-sm font-semibold text-slate-700">Set as active immediately</label>
                    </div>

                 </form>
                 
                 <div className="mt-8 pt-8 flex justify-center items-center gap-8">
                   <button type="button" onClick={() => setIsModalOpen(false)} disabled={isSaving} className="text-sm font-bold text-slate-700 hover:text-slate-900 transition-colors">
                     Discard Draft
                   </button>
                   <button type="submit" form="couponForm" disabled={isSaving} className="px-8 py-3.5 rounded-full text-sm font-bold text-white bg-[#6b46c1] hover:bg-[#5b3da6] transition-colors disabled:opacity-70 shadow-lg shadow-[#6b46c1]/20">
                     {editingCouponId ? (isSaving ? "Saving..." : "Update Coupon") : (isSaving ? "Saving..." : "Publish Coupon")}
                   </button>
                 </div>
               </div>
            </div>
          </div>
        )}

      </main>
    </>
  );
}
