"use client";

import { Plus, Edit2, Trash2, X, Image as ImageIcon, ChevronDown, Zap, ClipboardCheck, Star, AlertCircle, CheckCircle2 } from "lucide-react";
import { useEffect, useState, useMemo } from "react";
import { supabase } from "@/lib/supabase/client";
import ImageUploader from "@/components/ImageUploader";

const EMPTY_FORM = {
  name: "",
  brand: "",
  description: "",
  image_url: "",
  category_id: "",
  subcategory: "",
  sale_price: "",
  cashback: "",
  unit_size: "",
  unit: "pcs",
  mrp: "",
  stock_quantity: "",
  tags: [],
  is_organic: false,
  is_available: true,
  is_featured: false,
  is_active: true,
};

type Toast = { message: string; type: "success" | "error" };

export default function ProductsPage() {
  const [products, setProducts] = useState<any[]>([]);
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<Toast | null>(null);

  // Filters
  const [searchQuery, setSearchQuery] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("All Categories");
  const [statusFilter, setStatusFilter] = useState("All");

  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 8;

  // Modal state: null = closed, "add" = adding, "edit" = editing
  const [modalMode, setModalMode] = useState<null | "add" | "edit">(null);
  const [editingProductId, setEditingProductId] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [formData, setFormData] = useState({ ...EMPTY_FORM });

  // ─── Helpers ─────────────────────────────────────────────────────────────
  const showToast = (message: string, type: "success" | "error" = "success") => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3500);
  };

  const openAddModal = () => {
    setFormData({ ...EMPTY_FORM });
    setEditingProductId(null);
    setModalMode("add");
  };

  const openEditModal = (product: any) => {
    setFormData({
      name: product.name || "",
      brand: product.brand || "",
      description: product.description || "",
      image_url: product.image_url || "",
      category_id: product.category_id || "",
      subcategory: product.subcategory || "",
      sale_price: String(product.sale_price ?? ""),
      cashback: String(product.cashback ?? ""),
      unit_size: product.unit_size || "",
      unit: product.unit || "pcs",
      mrp: String(product.mrp ?? ""),
      stock_quantity: String(product.stock_qty ?? product.stock_count ?? ""),
      tags: product.tags || [],
      is_organic: product.is_organic ?? false,
      is_available: product.is_available ?? true,
      is_featured: product.is_featured ?? false,
      is_active: product.is_active ?? true,
    });
    setEditingProductId(product.id);
    setModalMode("edit");
  };

  const closeModal = () => {
    setModalMode(null);
    setEditingProductId(null);
    setFormData({ ...EMPTY_FORM });
  };

  // ─── Data Fetching ───────────────────────────────────────────────────────
  useEffect(() => { fetchData(); }, []);

  const fetchData = async () => {
    setLoading(true);
    const { data: catData } = await supabase.from("categories").select("id, name").order("name");
    if (catData) setCategories(catData);

    const { data: prodData } = await supabase
      .from("products")
      .select(`*, categories (name)`)
      .order("created_at", { ascending: false });

    if (prodData) setProducts(prodData);
    setLoading(false);
  };

  // ─── CRUD Handlers ───────────────────────────────────────────────────────
  const buildPayload = () => ({
    name: formData.name,
    brand: formData.brand,
    description: formData.description,
    image_url: formData.image_url,
    category_id: formData.category_id || null,
    subcategory: formData.subcategory,
    sale_price: parseFloat(formData.sale_price) || 0,
    cashback: parseFloat(formData.cashback) || 0,
    mrp: parseFloat(formData.mrp) || 0,
    unit_size: formData.unit_size,
    unit: formData.unit,
    stock_qty: parseInt(formData.stock_quantity) || 0,
    stock_count: parseInt(formData.stock_quantity) || 0,
    tags: formData.tags || [],
    is_organic: formData.is_organic,
    is_available: formData.is_available,
    is_featured: formData.is_featured,
    is_active: formData.is_active,
  });

  const handleAddProduct = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    const { error } = await supabase.from("products").insert([buildPayload()]);
    setIsSaving(false);
    if (error) {
      showToast(`Failed to add product: ${error.message}`, "error");
    } else {
      showToast("Product added successfully!");
      closeModal();
      fetchData();
    }
  };

  const handleUpdateProduct = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingProductId) return;
    setIsSaving(true);
    const { error } = await supabase.from("products").update(buildPayload()).eq("id", editingProductId);
    setIsSaving(false);
    if (error) {
      showToast(`Failed to update product: ${error.message}`, "error");
    } else {
      showToast("Product updated successfully!");
      closeModal();
      fetchData();
    }
  };

  const handleDeleteProduct = async (product: any) => {
    if (!confirm(`Delete "${product.name}"? This cannot be undone.`)) return;
    const { error } = await supabase.from("products").delete().eq("id", product.id);
    if (error) {
      showToast(`Failed to delete: ${error.message}`, "error");
    } else {
      showToast("Product deleted.");
      fetchData();
    }
  };

  const handleToggleActive = async (productId: string, currentStatus: boolean) => {
    setProducts(prev => prev.map(p => p.id === productId ? { ...p, is_active: !currentStatus } : p));
    await supabase.from("products").update({ is_active: !currentStatus }).eq("id", productId);
  };

  // ─── Filtering & Pagination ───────────────────────────────────────────────
  const filteredProducts = useMemo(() => {
    let result = products;
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      result = result.filter(p => p.name?.toLowerCase().includes(q) || p.id?.toLowerCase().includes(q));
    }
    if (categoryFilter !== "All Categories") result = result.filter(p => p.categories?.name === categoryFilter);
    if (statusFilter === "Active") result = result.filter(p => p.is_active);
    if (statusFilter === "Low Stock") result = result.filter(p => p.stock_qty > 0 && p.stock_qty < 10);
    if (statusFilter === "Out of Stock") result = result.filter(p => p.stock_qty === 0);
    return result;
  }, [products, searchQuery, categoryFilter, statusFilter]);

  const totalPages = Math.ceil(filteredProducts.length / itemsPerPage) || 1;
  const paginatedProducts = filteredProducts.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);

  useEffect(() => { setCurrentPage(1); }, [searchQuery, categoryFilter, statusFilter]);

  // ─── Render ───────────────────────────────────────────────────────────────
  return (
    <>
      {/* Toast */}
      {toast && (
        <div className={`fixed top-6 right-6 z-[100] flex items-center gap-3 px-5 py-4 rounded-2xl shadow-xl text-sm font-bold transition-all animate-fade-in-up ${toast.type === "success" ? "bg-emerald-600 text-white" : "bg-red-600 text-white"
          }`}>
          {toast.type === "success" ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
          {toast.message}
        </div>
      )}

      <header className="sticky top-0 w-full z-40 bg-white/80 backdrop-blur-xl border-b border-slate-100 flex justify-between items-center h-16 px-8">
        <div className="flex items-center gap-4 flex-1">
          <div className="relative w-full max-w-md">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="lucide lucide-search absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"><circle cx="11" cy="11" r="8" /><path d="m21 21-4.3-4.3" /></svg>
            <input type="text" placeholder="Search products..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-slate-50 border-none rounded-xl py-2 pl-9 pr-4 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all placeholder:text-slate-400" />
          </div>
        </div>
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-indigo-100 border border-indigo-200 flex items-center justify-center text-indigo-700 text-xs font-bold">A</div>
        </div>
      </header>

      <main className="p-8 bg-surface min-h-screen relative">
        <div className="flex justify-between items-end mb-8">
          <div>
            <h1 className="text-2xl font-bold text-on-surface tracking-tight">Products Management</h1>
            <p className="text-sm text-on-surface-variant mt-1">Manage your product catalog, inventory, and pricing.</p>
          </div>
          <button onClick={openAddModal} className="bg-gradient-to-br from-primary to-primary-container text-white px-5 py-2.5 rounded-xl font-semibold flex items-center gap-2 shadow-lg shadow-indigo-500/10 hover:shadow-indigo-500/20 transition-all">
            <Plus size={18} /> Add Product
          </button>
        </div>

        {/* Filter Bar */}
        <div className="bg-surface-container-lowest rounded-xl p-4 mb-6 flex flex-wrap items-center gap-4 shadow-sm">
          <div className="flex gap-2">
            {["All", "Active", "Low Stock", "Out of Stock"].map((f) => (
              <button key={f} onClick={() => setStatusFilter(f)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${statusFilter === f ? "bg-primary text-white shadow-sm" : "bg-surface-container-low text-on-surface-variant hover:bg-slate-200"}`}>
                {f}
              </button>
            ))}
          </div>
          <div className="ml-auto flex items-center gap-3">
            <select value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value)}
              className="border border-slate-200 bg-surface-container-low rounded-lg text-sm px-3 py-2 text-on-surface outline-none focus:border-indigo-500">
              <option>All Categories</option>
              {categories.map(c => <option key={c.id} value={c.name}>{c.name}</option>)}
            </select>
          </div>
        </div>

        {/* Products Table */}
        <div className="bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="bg-surface-container-low border-b border-slate-100">
                <tr>
                  {["Product", "Category", "Price", "Stock", "Active", "Actions"].map((h) => (
                    <th key={h} className="px-6 py-4 text-[11px] font-bold text-on-surface-variant uppercase tracking-wider">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50">
                {loading ? (
                  Array(5).fill(0).map((_, i) => (
                    <tr key={`sk-${i}`}>
                      <td className="px-6 py-4"><div className="flex gap-3"><div className="w-10 h-10 bg-slate-200 animate-pulse rounded-lg" /><div className="h-10 w-24 bg-slate-200 animate-pulse rounded" /></div></td>
                      <td className="px-6 py-4"><div className="h-6 w-16 bg-slate-200 animate-pulse rounded-full" /></td>
                      <td className="px-6 py-4"><div className="h-4 w-12 bg-slate-200 animate-pulse rounded" /></td>
                      <td className="px-6 py-4"><div className="h-4 w-8 bg-slate-200 animate-pulse rounded" /></td>
                      <td className="px-6 py-4"><div className="h-6 w-12 bg-slate-200 animate-pulse rounded-full" /></td>
                      <td className="px-6 py-4" />
                    </tr>
                  ))
                ) : paginatedProducts.length === 0 ? (
                  <tr><td colSpan={6} className="px-6 py-8 text-center text-slate-500 text-sm">No products found.</td></tr>
                ) : (
                  paginatedProducts.map((product) => (
                    <tr key={product.id} className="hover:bg-surface-container-low transition-colors group">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-lg bg-surface-container-low border border-slate-100 flex items-center justify-center overflow-hidden shrink-0">
                            {product.image_url ? (
                              <img src={product.image_url} alt={product.name} className="w-full h-full object-cover" />
                            ) : (
                              <ImageIcon size={20} className="text-slate-400" />
                            )}
                          </div>
                          <div>
                            <p className="text-sm font-bold text-on-surface line-clamp-1 max-w-[200px]">{product.name}</p>
                            <p className="text-[11px] text-on-surface-variant">{product.id.substring(0, 8)}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="text-[10px] bg-slate-100 px-2.5 py-1 rounded-full font-bold uppercase tracking-wider text-slate-600">
                          {product.categories?.name || "Uncategorized"}
                        </span>
                      </td>
                      <td className="px-6 py-4 font-bold text-on-surface">₹{(product.sale_price || 0).toFixed(2)}</td>
                      <td className="px-6 py-4">
                        <span className={`text-sm font-bold ${product.stock_qty === 0 ? "text-red-500" : product.stock_qty < 10 ? "text-amber-500" : "text-slate-700"
                          }`}>
                          {product.stock_qty}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <label className="relative inline-flex items-center cursor-pointer">
                          <input type="checkbox" className="sr-only peer" checked={product.is_active} onChange={() => handleToggleActive(product.id, product.is_active)} />
                          <div className="w-9 h-5 bg-slate-200 peer-focus:outline-none rounded-full peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-emerald-500"></div>
                        </label>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                          <button
                            onClick={() => openEditModal(product)}
                            className="p-1.5 text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                            title="Edit product"
                          >
                            <Edit2 size={16} />
                          </button>
                          <button
                            onClick={() => handleDeleteProduct(product)}
                            className="p-1.5 text-red-500 hover:bg-red-50 rounded-lg transition-colors"
                            title="Delete product"
                          >
                            <Trash2 size={16} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          <div className="px-6 py-4 bg-surface-container-low/30 border-t border-slate-100 flex items-center justify-between">
            <span className="text-xs text-on-surface-variant font-medium">
              {filteredProducts.length} product{filteredProducts.length !== 1 ? "s" : ""} &nbsp;·&nbsp; Page {currentPage} of {totalPages}
            </span>
            <div className="flex gap-2">
              <button onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}
                className="px-3 py-1 rounded-lg border border-outline-variant/30 text-xs font-bold disabled:opacity-50 disabled:cursor-not-allowed hover:bg-white bg-surface-container-low">
                Previous
              </button>
              <button onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages}
                className="px-3 py-1 rounded-lg bg-white border border-outline-variant/30 text-xs font-bold shadow-sm hover:bg-surface-container-low disabled:opacity-50 disabled:cursor-not-allowed">
                Next
              </button>
            </div>
          </div>
        </div>
      </main>

      {/* Product Form Modal (Add / Edit) */}
      {modalMode && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-0 md:p-6 lg:p-8">
          <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" onClick={() => !isSaving && closeModal()} />
          <div className="bg-[#F8F9FA] md:rounded-[32px] shadow-2xl w-full h-full md:h-auto max-h-[95vh] max-w-6xl overflow-hidden relative z-10 flex flex-col">
            
            {/* Top Toolbar */}
            <div className="px-8 py-5 bg-white border-b border-slate-100 flex items-center justify-between z-20">
               <div>
                 <h3 className="text-2xl font-black text-slate-900 tracking-tight">{modalMode === "edit" ? "Edit Product" : "Create New Product"}</h3>
                 <p className="text-sm text-slate-500 font-medium mt-1">Fill in the details below to add a premium item to your catalog.</p>
               </div>
               <div className="flex items-center gap-4">
                 <button onClick={closeModal} disabled={isSaving} className="text-sm font-bold text-slate-600 hover:text-slate-900 transition-colors">Discard Draft</button>
                 <button onClick={modalMode === "edit" ? handleUpdateProduct : handleAddProduct} disabled={isSaving} className="px-6 py-2.5 rounded-full text-sm font-bold text-white bg-[#5D3FD3] hover:bg-[#4b33a8] transition-colors shadow-lg shadow-[#5D3FD3]/20">
                   {isSaving ? "Saving..." : (modalMode === "edit" ? "Update Product" : "Save & Launch Product")}
                 </button>
                 <button onClick={closeModal} className="ml-4 p-2 bg-slate-100 rounded-full text-slate-400 hover:text-slate-700 hover:bg-slate-200 transition-colors">
                    <X size={18} />
                 </button>
               </div>
            </div>

            {/* Scrollable Content */}
            <div className="p-8 overflow-y-auto flex-1 pb-16">
              <form id="productForm" className="max-w-6xl mx-auto flex flex-col lg:flex-row gap-8">
                
                {/* LEFT COLUMN (Main Data) */}
                <div className="flex-1 space-y-6">
                   {/* Card 1: Basic Information */}
                   <div className="bg-white rounded-3xl p-8 shadow-sm border border-slate-100/50">
                      <div className="flex items-center gap-3 mb-6">
                         <div className="w-10 h-10 rounded-full bg-indigo-50 flex items-center justify-center text-[#5D3FD3]">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M4 22h14a2 2 0 0 0 2-2V7l-5-5H6a2 2 0 0 0-2 2v4"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="m3 15 2 2 4-4"/></svg>
                         </div>
                         <h4 className="text-lg font-bold text-slate-900">Basic Information</h4>
                      </div>
                      
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                        <div>
                          <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Product Name</label>
                          <input required type="text" value={formData.name} onChange={e => setFormData(f => ({ ...f, name: e.target.value }))}
                            className="w-full px-5 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#5D3FD3] outline-none font-medium text-slate-800 placeholder-slate-400" placeholder="e.g. Organic Madagascar Vanilla" />
                        </div>
                        <div>
                          <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Brand</label>
                          <input type="text" value={formData.brand} onChange={e => setFormData(f => ({ ...f, brand: e.target.value }))}
                            className="w-full px-5 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#5D3FD3] outline-none font-medium text-slate-800 placeholder-slate-400" placeholder="e.g. Earthly Gourmet" />
                        </div>
                      </div>

                      <div>
                         <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Description</label>
                         <textarea value={formData.description} onChange={e => setFormData(f => ({ ...f, description: e.target.value }))} rows={4}
                            className="w-full px-5 py-4 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#5D3FD3] outline-none font-medium text-slate-800 placeholder-slate-400 resize-none" placeholder="Describe the product's unique qualities..." />
                      </div>
                   </div>

                   {/* Card 2: Pricing Strategy */}
                   <div className="bg-white rounded-3xl p-8 shadow-sm border border-slate-100/50">
                      <div className="flex items-center gap-3 mb-6">
                         <div className="w-10 h-10 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-600">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><rect width="20" height="14" x="2" y="5" rx="2"/><line x1="2" x2="22" y1="10" y2="10"/></svg>
                         </div>
                         <h4 className="text-lg font-bold text-slate-900">Pricing Strategy</h4>
                      </div>

                      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                        <div>
                          <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">MRP</label>
                          <div className="relative">
                            <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 font-bold">₹</span>
                            <input required type="number" step="0.01" value={formData.mrp} onChange={e => setFormData(f => ({ ...f, mrp: e.target.value }))}
                              className="w-full pl-8 pr-4 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#5D3FD3] outline-none font-medium text-slate-800" placeholder="0.00" />
                          </div>
                        </div>
                        <div>
                          <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Selling Price</label>
                          <div className="relative">
                            <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 font-bold">₹</span>
                            <input required type="number" step="0.01" value={formData.sale_price} onChange={e => setFormData(f => ({ ...f, sale_price: e.target.value }))}
                              className="w-full pl-8 pr-4 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#5D3FD3] outline-none font-medium text-slate-800" placeholder="0.00" />
                          </div>
                        </div>
                        <div>
                          <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Discount</label>
                          <div className="relative h-[48px] bg-[#F3F4F6] rounded-2xl flex items-center px-5">
                            {(() => {
                              const mrp = parseFloat(formData.mrp) || 0;
                              const sale = parseFloat(formData.sale_price) || 0;
                              const discount = mrp > 0 && sale > 0 ? (((mrp - sale) / mrp) * 100).toFixed(0) : "0";
                              return (
                                <span className="text-sm font-bold text-rose-500">
                                  -{discount}% OFF
                                </span>
                              );
                            })()}
                          </div>
                        </div>
                        <div>
                          <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Cashback (₹)</label>
                          <div className="relative">
                            <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 font-bold">₹</span>
                            <input type="number" step="1" value={formData.cashback} onChange={e => setFormData(f => ({ ...f, cashback: e.target.value }))}
                              className="w-full pl-8 pr-4 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#5D3FD3] outline-none font-medium text-slate-800" placeholder="0" />
                          </div>
                        </div>
                      </div>

                      {/* Live Customer Preview */}
                      <div className="mt-6 p-4 rounded-xl border border-slate-200 bg-slate-50 flex items-center justify-center gap-3">
                        <span className="text-xs text-slate-500 uppercase font-bold tracking-wider mr-2">Preview:</span>
                        {(() => {
                          const mrpStr = formData.mrp ? `₹${formData.mrp}` : "₹0";
                          const saleStr = formData.sale_price ? `₹${formData.sale_price}` : "₹0";
                          const mrp = parseFloat(formData.mrp) || 0;
                          const sale = parseFloat(formData.sale_price) || 0;
                          const discount = mrp > 0 && sale > 0 ? (((mrp - sale) / mrp) * 100).toFixed(0) : "0";
                          return (
                            <span className="text-lg">
                              <span className="font-black text-slate-900">{saleStr}</span>
                              <span className="text-slate-400 line-through ml-2 text-sm">{mrpStr}</span>
                              {discount !== "0" && <span className="text-rose-500 font-bold ml-2 text-sm">-{discount}% OFF</span>}
                            </span>
                          );
                        })()}
                      </div>
                   </div>

                   {/* Card 3: Categorization */}
                   <div className="bg-white rounded-3xl p-8 shadow-sm border border-slate-100/50">
                      <div className="flex items-center gap-3 mb-6">
                         <div className="w-10 h-10 rounded-full bg-rose-50 flex items-center justify-center text-rose-600">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="m11 17 2 2a1 1 0 1 0 3-3"/><path d="m14 14 2.5 2.5a1 1 0 1 0 3-3l-3.88-3.88a3 3 0 0 0-4.24 0l-.88.88a1 1 0 1 1-3-3l2.81-2.81a5.79 5.79 0 0 1 7.06-.87l.47.28a2 2 0 0 0 1.42.25L21 4"/><path d="m21 3 1 11h-2"/><path d="M3 3 2 14l6.5 6.5a2 2 0 1 0 4-4Z"/><path d="M3 4h8S3 10 3 14"/></svg>
                         </div>
                         <h4 className="text-lg font-bold text-slate-900">Categorization</h4>
                      </div>

                      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                        <div>
                          <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Primary Category</label>
                          <div className="relative">
                            <select required value={formData.category_id} onChange={e => setFormData(f => ({ ...f, category_id: e.target.value }))}
                              className="w-full px-5 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#5D3FD3] outline-none font-medium text-slate-800 appearance-none">
                              <option value="" disabled>Select a Category...</option>
                              {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                            </select>
                            <ChevronDown size={18} className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                          </div>
                        </div>
                        <div>
                          <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Subcategory</label>
                          <input type="text" value={formData.subcategory || ""} onChange={e => setFormData(f => ({ ...f, subcategory: e.target.value }))}
                            className="w-full px-5 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#5D3FD3] outline-none font-medium text-slate-800 placeholder-slate-400" placeholder="e.g. Spices & Seasoning" />
                        </div>
                      </div>

                      <div>
                        <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Tags & Metadata</label>
                        <input type="text" value={(formData.tags || []).join(', ')} onChange={e => setFormData(f => ({ ...f, tags: e.target.value.split(',').map(s=>s.trim()).filter(Boolean) }))}
                            className="w-full px-5 py-3.5 bg-[#F3F4F6] border-none rounded-2xl text-sm focus:ring-2 focus:ring-[#5D3FD3] outline-none font-medium text-slate-800 placeholder-slate-400" placeholder="e.g. Organic, Gluten-Free, Exotic (comma separated)" />
                      </div>
                   </div>
                </div>

                {/* RIGHT COLUMN (Sidebar) */}
                <div className="w-full lg:w-[320px] xl:w-[380px] space-y-6">
                   
                   {/* Card 4: Product Image */}
                   <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100/50">
                      <h4 className="text-base font-bold text-slate-900 mb-4">Product Image</h4>
                      
                      <ImageUploader 
                        folder="products" 
                        onUpload={(url) => setFormData(f => ({ ...f, image_url: url }))} 
                        existingUrl={formData.image_url} 
                      />

                      <div className="mt-4">
                        <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Or Provide Remote URL</label>
                        <input type="text" value={formData.image_url} onChange={e => setFormData(f => ({ ...f, image_url: e.target.value }))}
                          className="w-full px-4 py-3 bg-[#F3F4F6] border-none rounded-xl text-sm focus:ring-2 focus:ring-[#5D3FD3] outline-none font-medium text-slate-800 placeholder-slate-400" placeholder="https://..." />
                      </div>
                   </div>

                   {/* Card 5: Inventory & Unit */}
                   <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100/50">
                      <h4 className="text-base font-bold text-slate-900 mb-4">Inventory & Unit</h4>
                      <div className="grid grid-cols-2 gap-4 mb-4">
                        <div>
                          <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Unit Size</label>
                          <input type="text" value={formData.unit_size || ""} onChange={e => setFormData(f => ({ ...f, unit_size: e.target.value }))}
                            className="w-full px-4 py-3 bg-[#F3F4F6] border-none rounded-xl text-sm focus:ring-2 focus:ring-[#5D3FD3] outline-none font-medium text-slate-800" placeholder="250" />
                        </div>
                        <div>
                          <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Unit</label>
                          <div className="relative">
                            <select value={formData.unit} onChange={e => setFormData(f => ({ ...f, unit: e.target.value }))}
                              className="w-full px-4 py-3 bg-[#F3F4F6] border-none rounded-xl text-sm focus:ring-2 focus:ring-[#5D3FD3] outline-none font-medium text-slate-800 appearance-none">
                              <option value="g">g</option>
                              <option value="kg">kg</option>
                              <option value="ml">ml</option>
                              <option value="l">l</option>
                              <option value="pcs">pcs</option>
                            </select>
                            <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                          </div>
                        </div>
                      </div>
                      <div>
                        <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Stock Quantity</label>
                        <input required type="number" value={formData.stock_quantity} onChange={e => setFormData(f => ({ ...f, stock_quantity: e.target.value }))}
                          className="w-full px-4 py-3 bg-[#F3F4F6] border-none rounded-xl text-sm focus:ring-2 focus:ring-[#5D3FD3] outline-none font-medium text-slate-800" placeholder="100" />
                      </div>
                   </div>

                   {/* Card 6: Toggles & Status */}
                   <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100/50 flex flex-col gap-6">
                      {[
                        { key: "is_available", label: "Is Available", desc: "Visible in customer shop" },
                        { key: "is_featured", label: "Featured Product", desc: "Show on homepage" },
                        { key: "is_organic", label: "Is Organic", desc: "Adds organic certification badge" }
                      ].map(({ key, label, desc }) => (
                         <div key={key} className="flex items-center justify-between">
                            <div>
                               <p className="text-sm font-bold text-slate-900">{label}</p>
                               <p className="text-[11px] text-slate-500 mt-0.5">{desc}</p>
                            </div>
                            <label className="relative inline-flex items-center cursor-pointer">
                              <input type="checkbox" className="sr-only peer" checked={(formData as any)[key]} onChange={e => setFormData(f => ({ ...f, [key]: e.target.checked }))} />
                              <div className="w-10 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#00897B]"></div>
                            </label>
                         </div>
                      ))}
                   </div>

                   {/* Card 7: System Status indicator */}
                   <div className="bg-[#E6F8F5] rounded-2xl p-5 border border-emerald-100/50 flex items-start gap-3">
                      <div className="w-4 h-4 rounded-full bg-[#00897B] mt-1 shrink-0 flex items-center justify-center">
                         <div className="w-1.5 h-1.5 bg-white rounded-full"></div>
                      </div>
                      <div>
                         <p className="text-sm font-bold text-slate-900">System Ready</p>
                         <p className="text-xs text-slate-600 mt-1 leading-relaxed">Changes are ready to be saved. Click 'Save & Launch Product' to publish live.</p>
                      </div>
                   </div>

                </div>
              </form>
            </div>

          </div>
        </div>
      )}
    </>
  );
}
