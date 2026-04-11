"use client";

import { Plus, Edit2, Trash2, X, Clock, Zap, Search, PlusCircle, MinusCircle, AlertCircle, CheckCircle2 } from "lucide-react";
import { useEffect, useState, useMemo, useRef } from "react";
import { supabase } from "@/lib/supabase/client";
import toast from "react-hot-toast";

type ToastMessage = { message: string; type: "success" | "error" };

type DealProduct = {
  id: string; // product id
  name: string;
  image_url: string;
  sale_price: number;
  mrp: number;
  unit: string;
  unit_size: string;
  overridePrice?: number | null;
  dealStock?: number | null;
};

type Deal = {
  id: string;
  title: string;
  subtitle: string;
  discount_percent: number;
  start_time: string;
  end_time: string;
  is_active: boolean;
  badge_color: string;
  flash_deal_products?: Array<{
    id: string;
    override_price: number | null;
    deal_stock: number | null;
    sold_count: number;
    product_id: string;
    products?: any;
  }>;
};

const BADGE_COLORS = [
  { label: "Red", value: "#FF4444" },
  { label: "Orange", value: "#F97316" },
  { label: "Purple", value: "#9333EA" },
  { label: "Blue", value: "#3B82F6" },
  { label: "Emerald", value: "#10B981" },
];

export default function FlashDealsPage() {
  const [deals, setDeals] = useState<Deal[]>([]);
  const [loading, setLoading] = useState(true);
  const [toastMsg, setToastMsg] = useState<ToastMessage | null>(null);

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [editingDealId, setEditingDealId] = useState<string | null>(null);
  
  // Deal Form
  const [title, setTitle] = useState("");
  const [subtitle, setSubtitle] = useState("");
  const [discountPercent, setDiscountPercent] = useState("");
  const [startTime, setStartTime] = useState("");
  const [endTime, setEndTime] = useState("");
  const [isActive, setIsActive] = useState(true);
  const [badgeColor, setBadgeColor] = useState("#FF4444");

  // Products Selection
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [selectedProducts, setSelectedProducts] = useState<DealProduct[]>([]);
  
  const searchTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    fetchDeals();
  }, []);

  const showToast = (message: string, type: "success" | "error" = "success") => {
    setToastMsg({ message, type });
    setTimeout(() => setToastMsg(null), 3500);
  };

  const fetchDeals = async () => {
    setLoading(true);
    const { data: dealsData } = await supabase
      .from("flash_deals")
      .select(`
         *,
         flash_deal_products (
           id, override_price, deal_stock, sold_count, product_id,
           products (id, name, image_url, sale_price, mrp, unit, unit_size)
         )
      `)
      .order("start_time", { ascending: false });

    if (dealsData) setDeals(dealsData as Deal[]);
    setLoading(false);
  };

  const openAddModal = () => {
    setEditingDealId(null);
    setTitle("");
    setSubtitle("");
    setDiscountPercent("");
    setStartTime("");
    setEndTime("");
    setIsActive(true);
    setBadgeColor("#FF4444");
    setSelectedProducts([]);
    setSearchQuery("");
    setSearchResults([]);
    setIsModalOpen(true);
  };

  const openEditModal = (deal: Deal) => {
    setEditingDealId(deal.id);
    setTitle(deal.title || "");
    setSubtitle(deal.subtitle || "");
    setDiscountPercent(deal.discount_percent?.toString() || "");
    setStartTime(deal.start_time ? new Date(deal.start_time).toISOString().slice(0, 16) : "");
    setEndTime(deal.end_time ? new Date(deal.end_time).toISOString().slice(0, 16) : "");
    setIsActive(deal.is_active ?? true);
    setBadgeColor(deal.badge_color || "#FF4444");

    const mappedProducts = (deal.flash_deal_products || []).map((fdp) => ({
      id: fdp.products?.id,
      name: fdp.products?.name,
      image_url: fdp.products?.image_url,
      sale_price: fdp.products?.sale_price,
      mrp: fdp.products?.mrp,
      unit: fdp.products?.unit,
      unit_size: fdp.products?.unit_size,
      overridePrice: fdp.override_price,
      dealStock: fdp.deal_stock,
    }));
    setSelectedProducts(mappedProducts as DealProduct[]);
    setSearchQuery("");
    setSearchResults([]);
    setIsModalOpen(true);
  };

  // Product Search logic
  useEffect(() => {
    if (searchTimeoutRef.current) clearTimeout(searchTimeoutRef.current);
    if (!searchQuery.trim()) {
      setSearchResults([]);
      setIsSearching(false);
      return;
    }

    setIsSearching(true);
    searchTimeoutRef.current = setTimeout(async () => {
      const { data } = await supabase
        .from('products')
        .select('id, name, image_url, sale_price, mrp, unit, unit_size')
        .ilike('name', `%${searchQuery}%`)
        .eq('is_active', true)
        .limit(10);
      
      setSearchResults(data || []);
      setIsSearching(false);
    }, 400);

    return () => {
      if (searchTimeoutRef.current) clearTimeout(searchTimeoutRef.current);
    };
  }, [searchQuery]);

  const addProductToDeal = (product: any) => {
    if (selectedProducts.find(p => p.id === product.id)) return;
    setSelectedProducts(prev => [...prev, { ...product, overridePrice: null, dealStock: null }]);
    setSearchQuery("");
  };

  const removeProductFromDeal = (productId: string) => {
    setSelectedProducts(prev => prev.filter(p => p.id !== productId));
  };

  const updateSelectedProduct = (productId: string, field: "overridePrice" | "dealStock", value: string) => {
    setSelectedProducts(prev => prev.map(p => {
      if (p.id === productId) {
        return { ...p, [field]: value === "" ? null : parseFloat(value) };
      }
      return p;
    }));
  };

  const saveDeal = async (e: React.FormEvent) => {
    e.preventDefault();
    if (selectedProducts.length === 0) {
      showToast("Please add at least one product.", "error");
      return;
    }
    
    setIsSaving(true);
    const loadingToast = toast.loading(editingDealId ? "Updating deal..." : "Creating deal...");

    try {
      // 1. Upsert flash_deal
      const dealPayload = {
        title,
        subtitle,
        discount_percent: parseInt(discountPercent) || 0,
        start_time: new Date(startTime).toISOString(),
        end_time: new Date(endTime).toISOString(),
        badge_color: badgeColor,
        is_active: isActive,
      };

      let dealId = editingDealId;

      if (editingDealId) {
        const { error } = await supabase.from('flash_deals').update(dealPayload).eq('id', editingDealId);
        if (error) throw error;
      } else {
        const { data: newDealData, error } = await supabase.from('flash_deals').insert([dealPayload]).select().single();
        if (error) throw error;
        dealId = newDealData.id;
      }

      // 2. Clear out old deal products if edit
      if (editingDealId) {
        await supabase.from('flash_deal_products').delete().eq('flash_deal_id', editingDealId);
      }

      // 3. Insert specific products
      const dealProducts = selectedProducts.map(p => ({
        flash_deal_id: dealId,
        product_id: p.id,
        override_price: p.overridePrice || null,
        deal_stock: p.dealStock || null,
      }));

      const { error: productsError } = await supabase.from('flash_deal_products').insert(dealProducts);
      if (productsError) throw productsError;

      toast.success('Flash deal saved!', { id: loadingToast });
      showToast(editingDealId ? "Deal updated successfully!" : "Deal created successfully!");
      setIsModalOpen(false);
      fetchDeals();
      
    } catch (error: any) {
      toast.error(error.message || 'Error saving deal', { id: loadingToast });
      showToast(error.message, "error");
    } finally {
      setIsSaving(false);
    }
  };

  const deleteDeal = async (id: string, titleStr: string) => {
    if (!confirm(`Are you sure you want to delete "${titleStr}"?`)) return;
    const { error } = await supabase.from('flash_deals').delete().eq('id', id);
    if (error) {
      showToast(error.message, "error");
    } else {
      showToast("Deal deleted.");
      fetchDeals();
    }
  };

  const toggleActive = async (id: string, current: boolean) => {
    setDeals(prev => prev.map(d => d.id === id ? { ...d, is_active: !current } : d));
    await supabase.from('flash_deals').update({ is_active: !current }).eq('id', id);
  };

  const getDealStatus = (deal: Deal) => {
    if (!deal.is_active) return { label: "Inactive", code: "inactive" };
    const now = new Date();
    const start = new Date(deal.start_time);
    const end = new Date(deal.end_time);

    if (now < start) return { label: "Scheduled", code: "scheduled" };
    if (now > end) return { label: "Expired", code: "expired" };
    return { label: "Live", code: "live" };
  };

  const activeDeals = deals.filter(d => getDealStatus(d).code === "live");
  const scheduledDeals = deals.filter(d => getDealStatus(d).code === "scheduled");
  const expiredDeals = deals.filter(d => getDealStatus(d).code === "expired" || getDealStatus(d).code === "inactive");

  return (
    <>
      {/* Toast */}
      {toastMsg && (
        <div className={`fixed top-6 right-6 z-[100] flex items-center gap-3 px-5 py-4 rounded-2xl shadow-xl text-sm font-bold transition-all animate-fade-in-up ${toastMsg.type === "success" ? "bg-emerald-600 text-white" : "bg-red-600 text-white"
          }`}>
          {toastMsg.type === "success" ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
          {toastMsg.message}
        </div>
      )}

      <header className="sticky top-0 w-full z-40 bg-white/80 backdrop-blur-xl border-b border-slate-100 flex justify-between items-center h-16 px-8">
        <div className="flex-1">
           <h2 className="font-bold text-slate-800">Flash Deals Management</h2>
        </div>
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-indigo-100 border border-indigo-200 flex items-center justify-center text-indigo-700 text-xs font-bold">A</div>
        </div>
      </header>

      <main className="p-8 bg-surface min-h-screen relative max-w-7xl mx-auto">
        <div className="flex justify-between items-end mb-8">
          <div>
            <h1 className="text-3xl font-black text-slate-900 tracking-tight">Flash Deals</h1>
            <p className="text-sm text-slate-500 font-medium mt-1">Group products into time-limited mega sales.</p>
          </div>
          <button onClick={openAddModal} className="bg-gradient-to-br from-indigo-600 to-indigo-800 text-white px-5 py-2.5 rounded-xl font-bold flex items-center gap-2 shadow-lg shadow-indigo-500/20 hover:shadow-indigo-500/30 transition-all">
            <Plus size={18} /> Create New Deal
          </button>
        </div>

        {loading ? (
           <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
             {[1,2,3].map(i => <div key={i} className="h-64 bg-slate-100 animate-pulse rounded-2xl" />)}
           </div>
        ) : (
          <div className="space-y-12">
            
            {/* Active Deals */}
            <section>
              <h3 className="text-lg font-bold text-slate-900 mb-4 flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
                Live Deals ({activeDeals.length})
              </h3>
              {activeDeals.length === 0 ? (
                <div className="p-8 border-2 border-dashed border-slate-200 rounded-2xl text-center">
                   <p className="text-slate-500 font-medium">No live deals running right now.</p>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {activeDeals.map(deal => <DealCard key={deal.id} deal={deal} onEdit={openEditModal} onDelete={deleteDeal} onToggle={toggleActive} />)}
                </div>
              )}
            </section>

            {/* Scheduled Deals */}
            {scheduledDeals.length > 0 && (
              <section>
                <h3 className="text-lg font-bold text-slate-900 mb-4 flex items-center gap-2">
                   <Clock size={18} className="text-indigo-500" />
                   Upcoming Deals ({scheduledDeals.length})
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {scheduledDeals.map(deal => <DealCard key={deal.id} deal={deal} onEdit={openEditModal} onDelete={deleteDeal} onToggle={toggleActive} />)}
                </div>
              </section>
            )}

            {/* Expired / Inactive */}
            {expiredDeals.length > 0 && (
              <section className="opacity-70 group hover:opacity-100 transition-opacity">
                <h3 className="text-lg font-bold text-slate-500 mb-4">Past & Inactive Deals ({expiredDeals.length})</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {expiredDeals.map(deal => <DealCard key={deal.id} deal={deal} onEdit={openEditModal} onDelete={deleteDeal} onToggle={toggleActive} />)}
                </div>
              </section>
            )}
          </div>
        )}
      </main>

      {/* CREATE / EDIT MODAL */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 md:p-8">
          <div className="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" onClick={() => !isSaving && setIsModalOpen(false)}></div>
          <div className="bg-[#F8F9FA] rounded-[24px] shadow-2xl w-full max-w-5xl h-[90vh] overflow-hidden relative z-10 flex flex-col">
            
            {/* Modal Header */}
            <div className="px-8 py-5 bg-white border-b border-slate-100 flex items-center justify-between shrink-0">
               <div>
                 <h3 className="text-2xl font-black text-slate-900 tracking-tight">{editingDealId ? "Edit Flash Deal" : "Create Flash Deal"}</h3>
               </div>
               <div className="flex items-center gap-4">
                 <button onClick={saveDeal} disabled={isSaving} className="px-6 py-2.5 rounded-full text-sm font-bold text-white bg-indigo-600 hover:bg-indigo-700 transition-colors shadow-lg shadow-indigo-600/20 disabled:opacity-50">
                   {isSaving ? "Saving..." : "Save Deal"}
                 </button>
                 <button onClick={() => setIsModalOpen(false)} className="p-2 bg-slate-100 rounded-full text-slate-400 hover:text-slate-700 hover:bg-slate-200 transition-colors">
                    <X size={18} />
                 </button>
               </div>
            </div>

            <div className="flex-1 overflow-y-auto p-8">
              <div className="flex flex-col lg:flex-row gap-8">
                
                {/* SECTION A: Deal Info */}
                <div className="w-full lg:w-1/3 space-y-6">
                  <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 line-h">
                     <h4 className="font-bold text-slate-900 mb-4">Deal Details</h4>
                     
                     <div className="space-y-4">
                        <div>
                          <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Title</label>
                          <input required type="text" value={title} onChange={e => setTitle(e.target.value)}
                            className="w-full px-4 py-3 bg-slate-50 border-none rounded-xl text-sm font-medium focus:ring-2 focus:ring-indigo-500 outline-none" placeholder="e.g. Weekend Flash Sale" />
                        </div>
                        <div>
                          <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Subtitle (Optional)</label>
                          <input type="text" value={subtitle} onChange={e => setSubtitle(e.target.value)}
                            className="w-full px-4 py-3 bg-slate-50 border-none rounded-xl text-sm font-medium focus:ring-2 focus:ring-indigo-500 outline-none" placeholder="e.g. Limited time only!" />
                        </div>
                        <div>
                          <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Base Discount %</label>
                          <div className="relative">
                            <input required type="number" min="0" max="100" value={discountPercent} onChange={e => setDiscountPercent(e.target.value)}
                              className="w-full pl-4 pr-10 py-3 bg-slate-50 border-none rounded-xl text-sm font-medium focus:ring-2 focus:ring-indigo-500 outline-none" placeholder="20" />
                            <span className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 font-bold">%</span>
                          </div>
                          <p className="text-[10px] text-slate-400 mt-1">Applies automatically to all products below unless overridden.</p>
                        </div>
                        
                        <div className="grid grid-cols-2 gap-3">
                           <div>
                             <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Start</label>
                             <input required type="datetime-local" value={startTime} onChange={e => setStartTime(e.target.value)}
                               className="w-full px-3 py-3 bg-slate-50 border-none rounded-xl text-xs font-medium focus:ring-2 focus:ring-indigo-500 outline-none" />
                           </div>
                           <div>
                             <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">End</label>
                             <input required type="datetime-local" value={endTime} onChange={e => setEndTime(e.target.value)}
                               className="w-full px-3 py-3 bg-slate-50 border-none rounded-xl text-xs font-medium focus:ring-2 focus:ring-indigo-500 outline-none" />
                           </div>
                        </div>

                        <div>
                          <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-3">Badge Theme</label>
                          <div className="flex gap-2">
                            {BADGE_COLORS.map(c => (
                              <button key={c.value} type="button" onClick={() => setBadgeColor(c.value)}
                                className={`w-8 h-8 rounded-full flex items-center justify-center transition-transform ${badgeColor === c.value ? 'scale-110 ring-2 ring-offset-2 ring-slate-800' : ''}`}
                                style={{ backgroundColor: c.value }} title={c.label}>
                                {badgeColor === c.value && <CheckCircle2 size={14} className="text-white" />}
                              </button>
                            ))}
                          </div>
                        </div>

                        <div className="pt-4 mt-4 border-t border-slate-100">
                          <label className="relative inline-flex items-center cursor-pointer">
                            <input type="checkbox" className="sr-only peer" checked={isActive} onChange={e => setIsActive(e.target.checked)} />
                            <div className="w-10 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600"></div>
                            <span className="ml-3 text-sm font-bold text-slate-700">Deal is active</span>
                          </label>
                        </div>
                     </div>
                  </div>
                </div>

                {/* SECTION B: Products List */}
                <div className="w-full lg:w-2/3 space-y-6">
                  <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 flex flex-col h-[70vh]">
                     <h4 className="font-bold text-slate-900 mb-4 bg-white">Associated Products</h4>
                     
                     {/* Search Bar */}
                     <div className="relative mb-6">
                        <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                        <input type="text" placeholder="Search products to add to deal..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)}
                          className="w-full bg-slate-50 border border-slate-200 rounded-xl py-3 pl-10 pr-4 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all placeholder:text-slate-400 font-medium" />
                        
                        {/* Search dropdown */}
                        {searchQuery && (
                          <div className="absolute top-full left-0 right-0 mt-2 bg-white rounded-xl shadow-xl border border-slate-100 overflow-hidden z-50">
                            {isSearching ? (
                               <div className="p-4 text-center text-sm text-slate-500 font-medium">Searching...</div>
                            ) : searchResults.length === 0 ? (
                               <div className="p-4 text-center text-sm text-slate-500 font-medium">No active products found matching "{searchQuery}"</div>
                            ) : (
                               <ul className="max-h-64 overflow-y-auto">
                                 {searchResults.map(p => (
                                    <li key={p.id}>
                                       <button type="button" onClick={() => addProductToDeal(p)} className="w-full text-left px-4 py-3 hover:bg-slate-50 border-b border-slate-50 flex items-center gap-3">
                                          <div className="w-10 h-10 bg-white border border-slate-100 rounded-lg overflow-hidden shrink-0">
                                            {p.image_url ? <img src={p.image_url} alt="" className="w-full h-full object-cover" /> : null}
                                          </div>
                                          <div className="flex-1">
                                             <p className="text-sm font-bold text-slate-900 line-clamp-1">{p.name}</p>
                                             <p className="text-[10px] font-medium text-slate-500">₹{p.sale_price} • {p.unit_size}{p.unit}</p>
                                          </div>
                                          <PlusCircle size={18} className="text-indigo-500 shrink-0" />
                                       </button>
                                    </li>
                                 ))}
                               </ul>
                            )}
                          </div>
                        )}
                     </div>

                     {/* Product List */}
                     <div className="flex-1 overflow-y-auto bg-slate-50 rounded-xl border border-slate-100 p-2">
                        {selectedProducts.length === 0 ? (
                          <div className="h-full flex flex-col items-center justify-center text-slate-400">
                             <Zap size={48} className="opacity-20 mb-4" />
                             <p className="font-medium text-sm">No products added yet.</p>
                             <p className="text-xs">Search and click to add items to this flash deal.</p>
                          </div>
                        ) : (
                          <div className="space-y-2">
                            {selectedProducts.map((p, index) => {
                               const defaultDealPrice = p.sale_price * (1 - (parseInt(discountPercent)||0) / 100);
                               const dealPrice = p.overridePrice ?? defaultDealPrice;

                               return (
                                 <div key={p.id} className="bg-white p-3 rounded-lg border border-slate-100 shadow-sm flex items-center gap-4 group">
                                    <div className="text-xs font-bold text-slate-400 w-4 text-center">{index + 1}</div>
                                    <div className="w-12 h-12 border border-slate-100 rounded-lg overflow-hidden shrink-0">
                                      {p.image_url && <img src={p.image_url} alt="" className="w-full h-full object-cover" />}
                                    </div>
                                    <div className="flex-1 min-w-0">
                                       <p className="text-sm font-bold text-slate-900 truncate">{p.name}</p>
                                       <div className="flex items-center gap-2 mt-0.5">
                                          <span className="text-xs text-slate-400 line-through">₹{p.sale_price}</span>
                                          <span className="text-sm font-black text-rose-500">₹{dealPrice.toFixed(2)}</span>
                                       </div>
                                    </div>
                                    
                                    {/* Overrides */}
                                    <div className="flex gap-3 shrink-0">
                                      <div className="w-24">
                                        <label className="block text-[9px] font-bold text-slate-400 uppercase mb-1">Custom Price</label>
                                        <div className="relative">
                                          <span className="absolute left-2 top-1/2 -translate-y-1/2 text-slate-400 font-bold text-xs">₹</span>
                                          <input type="number" step="0.01" value={p.overridePrice === null ? "" : p.overridePrice} onChange={e => updateSelectedProduct(p.id, 'overridePrice', e.target.value)}
                                            className="w-full pl-5 pr-2 py-1.5 bg-slate-50 border border-slate-200 rounded text-xs font-bold outline-none focus:border-indigo-500" placeholder="Auto" />
                                        </div>
                                      </div>
                                      <div className="w-20">
                                        <label className="block text-[9px] font-bold text-slate-400 uppercase mb-1">Stock Limit</label>
                                        <input type="number" min="1" value={p.dealStock === null ? "" : p.dealStock} onChange={e => updateSelectedProduct(p.id, 'dealStock', e.target.value)}
                                            className="w-full px-2 py-1.5 bg-slate-50 border border-slate-200 rounded text-xs font-bold outline-none focus:border-indigo-500" placeholder="Unlmtd" />
                                      </div>
                                    </div>

                                    <button type="button" onClick={() => removeProductFromDeal(p.id)} className="w-8 h-8 rounded flex items-center justify-center text-slate-300 hover:bg-rose-50 hover:text-rose-500 transition-colors shrink-0 outline-none">
                                      <X size={16} strokeWidth={3} />
                                    </button>
                                 </div>
                               );
                            })}
                          </div>
                        )}
                     </div>

                  </div>
                </div>

              </div>
            </div>

          </div>
        </div>
      )}
    </>
  );
}

function DealCard({ deal, onEdit, onDelete, onToggle }: { deal: Deal, onEdit: (d: Deal)=>void, onDelete: (id: string, name: string)=>void, onToggle: (id: string, current: boolean)=>void }) {
  
  const [timeLeft, setTimeLeft] = useState('');
  
  useEffect(() => {
    const end = new Date(deal.end_time).getTime();
    
    const updateTime = () => {
      const now = new Date().getTime();
      const diff = end - now;
      
      if (diff <= 0) {
        setTimeLeft('Expired');
        return;
      }
      
      const hours = Math.floor(diff / (1000 * 60 * 60));
      const mins = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
      const secs = Math.floor((diff % (1000 * 60)) / 1000);
      
      setTimeLeft(
        `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
      );
    };

    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, [deal.end_time]);

  const isLive = deal.is_active && new Date(deal.start_time) < new Date() && new Date(deal.end_time) > new Date();
  const productCount = deal.flash_deal_products?.length || 0;

  return (
    <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100 flex flex-col relative overflow-hidden group hover:shadow-md transition-shadow">
       {/* Left Accent */}
       <div className="absolute left-0 top-0 bottom-0 w-1.5" style={{ backgroundColor: deal.badge_color || '#FF4444' }} />

       <div className="flex justify-between items-start mb-4 pl-2">
         <div className="pr-4">
           {isLive && (
             <div className="flex items-center gap-1.5 mb-2">
               <div className="w-2 h-2 rounded-full animate-pulse" style={{ backgroundColor: deal.badge_color || '#FF4444' }} />
               <span className="text-[10px] font-black uppercase tracking-widest text-slate-500">Live Now</span>
             </div>
           )}
           <h3 className="text-lg font-black text-slate-900 tracking-tight leading-tight">{deal.title}</h3>
           {deal.subtitle && <p className="text-xs text-slate-500 font-medium mt-1">{deal.subtitle}</p>}
         </div>
         <div className="shrink-0 bg-slate-50 px-2.5 py-1 rounded-lg border border-slate-100 font-black text-sm" style={{ color: deal.badge_color || '#FF4444' }}>
            {deal.discount_percent}% OFF
         </div>
       </div>

       <div className="flex-1 pl-2 mb-6">
         <div className="flex items-center gap-4 text-xs font-bold text-slate-600 mb-2">
            <span className="flex items-center gap-1.5"><Clock size={14} className="text-slate-400" /> {timeLeft}</span>
         </div>
         <p className="text-xs font-semibold text-slate-500">Contains {productCount} item{productCount !== 1 ? 's' : ''}</p>
       </div>

       {/* Actions */}
       <div className="flex items-center justify-between pl-2 pt-4 border-t border-slate-50">
          <label className="relative inline-flex items-center cursor-pointer">
            <input type="checkbox" className="sr-only peer" checked={deal.is_active} onChange={() => onToggle(deal.id, deal.is_active)} />
            <div className={`w-8 h-4 bg-slate-200 peer-focus:outline-none rounded-full peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-3 after:w-3 after:transition-all peer-checked:bg-emerald-500`}></div>
          </label>

          <div className="flex gap-2">
             <button onClick={() => onEdit(deal)} className="p-1.5 text-indigo-600 hover:bg-indigo-50 rounded transition-colors" title="Edit Deal">
                <Edit2 size={16} />
             </button>
             <button onClick={() => onDelete(deal.id, deal.title)} className="p-1.5 text-rose-500 hover:bg-rose-50 rounded transition-colors" title="Delete Deal">
                <Trash2 size={16} />
             </button>
          </div>
       </div>
    </div>
  );
}
