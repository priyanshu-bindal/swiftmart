"use client";

import { Plus, Zap, Edit2, Trash2, Clock, X } from "lucide-react";
import { useEffect, useState, useMemo } from "react";
import { supabase } from "@/lib/supabase/client";
import toast from "react-hot-toast";

export default function DealsPage() {
  const [deals, setDeals] = useState<any[]>([]);
  const [products, setProducts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // Filters
  const [searchQuery, setSearchQuery] = useState("");

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [editingDealId, setEditingDealId] = useState<string | null>(null);
  
  // New Deal Form
  const [newDeal, setNewDeal] = useState({
    product_id: "",
    discount_pct: "",
    max_qty: "",
    start_time: "",
    end_time: "",
    is_active: true,
  });

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);

    const { data: prodData } = await supabase.from("products").select("id, name, original_price").order("name");
    if (prodData) setProducts(prodData);

    const { data: dealsData } = await supabase
      .from("flash_deals")
      .select(`
         *,
         products (name, category_id, original_price, stock_quantity, categories(name))
      `)
      .order("start_time", { ascending: false });

    if (dealsData) setDeals(dealsData);
    setLoading(false);
  };

  const handleSaveDeal = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    const loadingToast = toast.loading(editingDealId ? "Updating flash deal..." : "Creating flash deal...");
    
    try {
      const payload = {
        product_id: newDeal.product_id,
        discount_pct: parseFloat(newDeal.discount_pct) || 0,
        max_qty: parseInt(newDeal.max_qty) || 0,
        start_time: new Date(newDeal.start_time).toISOString(),
        end_time: new Date(newDeal.end_time).toISOString(),
        is_active: newDeal.is_active,
      };

      let error;
      if (editingDealId) {
        const { error: updateError } = await supabase.from("flash_deals").update(payload).eq("id", editingDealId);
        error = updateError;
      } else {
        const { error: insertError } = await supabase.from("flash_deals").insert([payload]);
        error = insertError;
      }

      if (error) throw error;
      
      toast.success(editingDealId ? "Flash deal updated!" : "Flash deal created!", { id: loadingToast });
      setIsModalOpen(false);
      
      // Reset form
      setNewDeal({
         product_id: "", discount_pct: "", max_qty: "", start_time: "", end_time: "", is_active: true
      });
      setEditingDealId(null);
      fetchData();
    } catch (error: any) {
      toast.error(error.message || "An error occurred", { id: loadingToast });
    } finally {
      setIsSaving(false);
    }
  };

  const openEditModal = (deal: any) => {
    setEditingDealId(deal.id);
    setNewDeal({
      product_id: deal.product_id || "",
      discount_pct: deal.discount_pct?.toString() || "",
      max_qty: deal.max_qty?.toString() || "",
      start_time: deal.start_time ? new Date(deal.start_time).toISOString().slice(0, 16) : "",
      end_time: deal.end_time ? new Date(deal.end_time).toISOString().slice(0, 16) : "",
      is_active: deal.is_active ?? true,
    });
    setIsModalOpen(true);
  };

  const filteredDeals = useMemo(() => {
    let result = deals;
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      result = result.filter(d => 
         (d.products?.name || "").toLowerCase().includes(q)
      );
    }
    return result;
  }, [deals, searchQuery]);

  const activeDeals = deals.filter(d => d.is_active && new Date(d.end_time) > new Date() && new Date(d.start_time) <= new Date());
  
  // Find currently active featured
  const featured = activeDeals[0] || deals[0]; 

  const getDealStatus = (deal: any) => {
     if (!deal.is_active) return { label: "Inactive", color: "bg-slate-100 text-slate-700" };
     const now = new Date();
     const start = new Date(deal.start_time);
     const end = new Date(deal.end_time);

     if (now < start) return { label: "Scheduled", color: "bg-indigo-100 text-indigo-700" };
     if (now > end) return { label: "Expired", color: "bg-red-100 text-red-700" };
     
     // Live
     const hoursLeft = (end.getTime() - now.getTime()) / (1000 * 60 * 60);
     if (hoursLeft < 24) return { label: "Ending Soon", color: "bg-amber-100 text-amber-700" };
     return { label: "Live", color: "bg-emerald-100 text-emerald-700" };
  };

  const formatCountdown = (dateString: string) => {
     const end = new Date(dateString);
     const now = new Date();
     if (now > end) return "Expired";
     const diff = end.getTime() - now.getTime();
     const h = Math.floor(diff / (1000 * 60 * 60));
     const m = Math.floor((diff / (1000 * 60)) % 60);
     return `${h}h ${m}m left`;
  };

  return (
    <>
      <header className="sticky top-0 w-full z-40 bg-white/80 backdrop-blur-xl border-b border-slate-100 flex justify-between items-center h-16 px-8">
        <div className="flex items-center gap-4 flex-1">
          <div className="relative w-full max-w-md">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="lucide lucide-search absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <input
              type="text"
              placeholder="Search flash deals..."
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
              Flash Deals & Offers
            </h1>
            <p className="text-sm text-on-surface-variant mt-1">
              Create time-limited deals to drive urgency and boost conversions.
            </p>
          </div>
          <button onClick={() => {
            setEditingDealId(null);
            setNewDeal({ product_id: "", discount_pct: "", max_qty: "", start_time: "", end_time: "", is_active: true });
            setIsModalOpen(true);
          }} className="bg-gradient-to-br from-primary to-primary-container text-white px-5 py-2.5 rounded-xl font-semibold flex items-center gap-2 shadow-lg shadow-indigo-500/10 hover:shadow-indigo-500/20 transition-all">
            <Plus size={18} />
            Create Deal
          </button>
        </div>

        {/* Active Deal Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          {[
            { label: "Active Deals", value: loading ? "..." : activeDeals.length.toString(), color: "text-emerald-600" },
            { label: "Total Revenue Today", value: "N/A", color: "text-on-surface" }, // Mocked
            { label: "Items Sold", value: "N/A", color: "text-primary" },
            { label: "Avg. Discount", value: "N/A", color: "text-secondary" },
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

        {/* Featured Live Deal Banner */}
        {!loading && featured && (
           <div className="mb-8 bg-gradient-to-br from-indigo-900 to-indigo-700 rounded-2xl p-8 text-white relative overflow-hidden">
             <div className="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/4" />
             <div className="relative flex flex-col md:flex-row items-center justify-between gap-8">
               <div className="flex-1 w-full">
                 <div className="flex items-center gap-3 mb-4">
                   <div className="bg-white/20 p-2 rounded-lg animate-pulse">
                     <Zap size={20} />
                   </div>
                   <span className="text-white/80 text-sm font-medium uppercase tracking-widest">
                     {getDealStatus(featured).label}
                   </span>
                 </div>
                 <h2 className="text-3xl font-black tracking-tight mb-2">
                   {featured.products?.name}
                 </h2>
                 <p className="text-white/70 text-sm mb-6">
                   Up to {featured.discount_pct}% off on premium {featured.products?.categories?.name} — limited time only!
                 </p>
                 <div className="flex items-center gap-4 wrap">
                   <div>
                     <p className="text-white/60 text-xs uppercase">Time Remaining</p>
                     <p className="text-2xl font-mono font-black">{formatCountdown(featured.end_time)}</p>
                   </div>
                   <div className="h-10 w-px bg-white/20" />
                   <div>
                     <p className="text-white/60 text-xs uppercase">Max Qty Allowed</p>
                     <p className="text-2xl font-black">{featured.max_qty}</p>
                   </div>
                 </div>
               </div>
               <div className="text-center bg-white/10 backdrop-blur-sm rounded-2xl p-8 w-full md:w-auto shrink-0">
                 <p className="text-white/60 text-sm line-through">₹{(featured.products?.original_price || 0).toFixed(2)}</p>
                 <p className="text-5xl font-black">₹{((featured.products?.original_price || 0) * (1 - featured.discount_pct/100)).toFixed(2)}</p>
                 <div className="mt-2 bg-secondary-container text-on-secondary-container text-xs font-black px-3 py-1 rounded-full inline-block">
                   {featured.discount_pct}% OFF
                 </div>
               </div>
             </div>
           </div>
        )}

        {/* Deals Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {loading ? (
             Array(4).fill(0).map((_, i) => (
                <div key={i} className="bg-surface-container-lowest rounded-xl p-6 shadow-sm border border-outline-variant/10">
                   <div className="h-4 w-16 bg-slate-200 animate-pulse rounded mb-2" />
                   <div className="h-6 w-48 bg-slate-200 animate-pulse rounded mb-4" />
                   <div className="h-10 w-full bg-slate-200 animate-pulse rounded mb-4" />
                   <div className="h-4 w-full bg-slate-200 animate-pulse rounded" />
                </div>
             ))
          ) : filteredDeals.length === 0 ? (
             <div className="col-span-1 md:col-span-2 py-12 text-center text-slate-500 font-medium">No deals found.</div>
          ) : (
            filteredDeals.map((deal) => {
              const status = getDealStatus(deal);
              const originalPrice = deal.products?.original_price || 0;
              const dealPrice = originalPrice * (1 - deal.discount_pct/100);
              const stock = deal.products?.stock_quantity || 0;
              const totalStock = deal.max_qty;

              return (
                <div
                  key={deal.id}
                  className="bg-surface-container-lowest rounded-xl p-6 shadow-sm border border-outline-variant/10 group hover:shadow-md transition-shadow"
                >
                  <div className="flex justify-between items-start mb-4">
                    <div>
                      <span className="text-xs font-bold text-on-surface-variant bg-surface-container-low px-2 py-1 rounded-md">
                        {deal.products?.categories?.name || "Uncategorized"}
                      </span>
                      <h3 className="text-base font-bold text-on-surface mt-2 line-clamp-1">
                        {deal.products?.name}
                      </h3>
                    </div>
                    <span
                      className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${status.color}`}
                    >
                      {status.label === "Live" && <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />}
                      {status.label}
                    </span>
                  </div>

                  <div className="flex flex-wrap items-center gap-4 mb-4">
                    <div>
                      <p className="text-xs text-on-surface-variant line-through">
                        ₹{originalPrice.toFixed(2)}
                      </p>
                      <p className="text-2xl font-bold text-on-surface">
                        ₹{dealPrice.toFixed(2)}
                      </p>
                    </div>
                    <div className="bg-secondary-container text-on-secondary-container text-xs font-black px-3 py-1.5 rounded-lg">
                      {deal.discount_pct}% OFF
                    </div>
                    <div className="ml-auto flex items-center gap-1 text-on-surface-variant text-xs font-medium">
                      <Clock size={12} />
                      {formatCountdown(deal.end_time)}
                    </div>
                  </div>

                  {/* Stock bar */}
                  <div className="mb-4">
                    <div className="flex justify-between text-xs text-on-surface-variant mb-1 font-medium">
                      <span>Products Stock: {stock} left</span>
                      <span>Max Qty Allowed: {totalStock}</span>
                    </div>
                    <div className="h-2 bg-surface-container-low rounded-full overflow-hidden">
                      <div
                        className={`h-full rounded-full ${
                          stock === 0
                            ? "bg-red-400"
                            : stock < 15
                            ? "bg-amber-400"
                            : "bg-gradient-to-r from-primary to-primary-container"
                        }`}
                        style={{
                          width: `${Math.min((stock / (totalStock || 1)) * 100, 100)}%`,
                        }}
                      />
                    </div>
                  </div>

                  <div className="flex items-center gap-2 pt-2 border-t border-slate-50 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button onClick={() => openEditModal(deal)} className="flex-1 py-1.5 text-xs font-bold text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors flex items-center justify-center gap-1">
                      <Edit2 size={13} /> Edit
                    </button>
                    <button 
                       onClick={async () => {
                          if (confirm("Delete deal?")) {
                             const loadingToast = toast.loading("Deleting flash deal...");
                             const { error } = await supabase.from("flash_deals").delete().eq("id", deal.id);
                             if (error) {
                                toast.error("Failed to delete deal", { id: loadingToast });
                             } else {
                                toast.success("Flash deal deleted", { id: loadingToast });
                                fetchData();
                             }
                          }
                       }}
                       className="flex-1 py-1.5 text-xs font-bold text-error hover:bg-error-container/20 rounded-lg transition-colors flex items-center justify-center gap-1">
                      <Trash2 size={13} /> Delete
                    </button>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Add Deal Modal */}
        {isModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" onClick={() => !isSaving && setIsModalOpen(false)}></div>
            <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden relative z-10 animate-fade-in-up flex flex-col max-h-[90vh]">
               <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center bg-slate-50">
                  <h3 className="text-lg font-bold text-slate-900">{editingDealId ? "Edit Flash Deal" : "Create Flash Deal"}</h3>
                  <button onClick={() => setIsModalOpen(false)} disabled={isSaving} className="text-slate-400 hover:text-slate-700">
                     <X size={20} />
                  </button>
               </div>
               
               <div className="p-6 overflow-y-auto">
                 <form id="dealForm" onSubmit={handleSaveDeal} className="space-y-4">
                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">Select Product</label>
                      <select required value={newDeal.product_id} onChange={e => setNewDeal({...newDeal, product_id: e.target.value})} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none bg-white">
                         <option value="" disabled>Select a product...</option>
                         {products.map(p => (
                            <option key={p.id} value={p.id}>{p.name} (₹{p.original_price})</option>
                         ))}
                      </select>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-xs font-bold text-slate-700 mb-1">Discount (%)</label>
                        <input required type="number" min="0" max="100" step="0.1" value={newDeal.discount_pct} onChange={e => setNewDeal({...newDeal, discount_pct: e.target.value})} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none" />
                      </div>
                      <div>
                        <label className="block text-xs font-bold text-slate-700 mb-1">Max Qty Allowed</label>
                        <input required type="number" min="1" value={newDeal.max_qty} onChange={e => setNewDeal({...newDeal, max_qty: e.target.value})} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none" />
                      </div>
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">Start Time</label>
                      <input required type="datetime-local" value={newDeal.start_time} onChange={e => setNewDeal({...newDeal, start_time: e.target.value})} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none" />
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">End Time</label>
                      <input required type="datetime-local" value={newDeal.end_time} onChange={e => setNewDeal({...newDeal, end_time: e.target.value})} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none" />
                    </div>

                    <div className="flex items-center gap-2 mt-2">
                       <input type="checkbox" id="isActive" checked={newDeal.is_active} onChange={e => setNewDeal({...newDeal, is_active: e.target.checked})} className="rounded text-indigo-600 focus:ring-indigo-500 disabled:opacity-50" />
                       <label htmlFor="isActive" className="text-sm font-semibold text-slate-700">Set as active</label>
                    </div>
                 </form>
               </div>
               
               <div className="px-6 py-4 border-t border-slate-100 flex justify-end gap-3 bg-slate-50">
                 <button type="button" onClick={() => setIsModalOpen(false)} disabled={isSaving} className="px-4 py-2 rounded-lg text-sm font-bold text-slate-600 hover:bg-slate-200 transition-colors">
                   Cancel
                 </button>
                 <button type="submit" form="dealForm" disabled={isSaving} className="px-4 py-2 rounded-lg text-sm font-bold text-white bg-indigo-600 hover:bg-indigo-700 transition-colors disabled:opacity-70">
                   {isSaving ? "Saving..." : "Save Deal"}
                 </button>
               </div>
            </div>
          </div>
        )}

      </main>
    </>
  );
}
