"use client";

import { Plus, Edit2, Trash2, X, Image as ImageIcon } from "lucide-react";
import { useEffect, useState, useMemo } from "react";
import { supabase } from "@/lib/supabase/client";
import ImageUploader from "@/components/ImageUploader";
import toast from "react-hot-toast";

export default function CategoriesPage() {
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // Filters
  const [searchQuery, setSearchQuery] = useState("");

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [editingCatId, setEditingCatId] = useState<string | null>(null);
  
  // New Category Form
  const [newCat, setNewCat] = useState({
    name: "",
    image_url: "",
    sort_order: 0,
    is_active: true,
  });

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);

    const { data: catData } = await supabase
      .from("categories")
      .select(`*, products(id)`)
      .order("sort_order", { ascending: true });

    if (catData) setCategories(catData);
    setLoading(false);
  };

  const handleSaveCategory = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    const loadingToast = toast.loading(editingCatId ? "Updating category..." : "Adding category...");
    
    try {
      const payload = {
        name: newCat.name,
        image_url: newCat.image_url,
        sort_order: parseInt(newCat.sort_order.toString()) || 0,
        is_active: newCat.is_active,
      };

      let error;
      if (editingCatId) {
        const { error: updateError } = await supabase.from("categories").update(payload).eq("id", editingCatId);
        error = updateError;
      } else {
        const { error: insertError } = await supabase.from("categories").insert([payload]);
        error = insertError;
      }

      if (error) throw error;
      
      toast.success(editingCatId ? "Category updated!" : "Category created!", { id: loadingToast });
      setIsModalOpen(false);
      
      // Reset form
      setNewCat({
        name: "", image_url: "", sort_order: 0, is_active: true
      });
      setEditingCatId(null);
      fetchData();
    } catch (error: any) {
      toast.error(error.message || "An error occurred", { id: loadingToast });
    } finally {
      setIsSaving(false);
    }
  };

  const openEditModal = (cat: any) => {
    setEditingCatId(cat.id);
    setNewCat({
      name: cat.name || "",
      image_url: cat.image_url || "",
      sort_order: cat.sort_order || 0,
      is_active: cat.is_active ?? true,
    });
    setIsModalOpen(true);
  };

  const toggleStatus = async (cat: any) => {
    const loadingToast = toast.loading("Updating status...");
    const { error } = await supabase.from("categories").update({ is_active: !cat.is_active }).eq("id", cat.id);
    if (error) {
      toast.error("Failed to update status", { id: loadingToast });
    } else {
      toast.success("Status updated", { id: loadingToast });
      fetchData();
    }
  };

  const filteredCategories = useMemo(() => {
    let result = categories;
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      result = result.filter(c => c.name.toLowerCase().includes(q));
    }
    return result;
  }, [categories, searchQuery]);

  // Derived Stats
  const totalCategories = categories.length;
  const activeCategories = categories.filter(c => c.is_active).length;
  const totalProducts = categories.reduce((sum, c) => sum + (c.products?.length || 0), 0);

  const colors = [
    { bg: "bg-indigo-50", text: "text-indigo-700" },
    { bg: "bg-amber-50", text: "text-amber-700" },
    { bg: "bg-emerald-50", text: "text-emerald-700" },
    { bg: "bg-purple-50", text: "text-purple-700" },
    { bg: "bg-rose-50", text: "text-rose-700" },
    { bg: "bg-sky-50", text: "text-sky-700" },
  ];

  return (
    <>
      <header className="sticky top-0 w-full z-40 bg-white/80 backdrop-blur-xl border-b border-slate-100 flex justify-between items-center h-16 px-8">
        <div className="flex items-center gap-4 flex-1">
          <div className="relative w-full max-w-md">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="lucide lucide-search absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <input
              type="text"
              placeholder="Search categories..."
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
              Categories Management
            </h1>
            <p className="text-sm text-on-surface-variant mt-1">
              Organize your product taxonomy and category hierarchy.
            </p>
          </div>
          <button onClick={() => {
            setEditingCatId(null);
            setNewCat({ name: "", image_url: "", sort_order: 0, is_active: true });
            setIsModalOpen(true);
          }} className="bg-gradient-to-br from-primary to-primary-container text-white px-5 py-2.5 rounded-xl font-semibold flex items-center gap-2 shadow-lg shadow-indigo-500/10 hover:shadow-indigo-500/20 transition-all">
            <Plus size={18} />
            Add Category
          </button>
        </div>

        {/* Stats Row */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-outline-variant/10">
            <p className="text-xs font-bold text-on-surface-variant uppercase tracking-wider mb-2">
              Total Categories
            </p>
            {loading ? <div className="h-8 w-16 bg-slate-200 animate-pulse rounded" /> : <p className="text-3xl font-bold text-on-surface">{totalCategories}</p>}
          </div>
          <div className="bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-outline-variant/10">
            <p className="text-xs font-bold text-on-surface-variant uppercase tracking-wider mb-2">
              Active Categories
            </p>
            {loading ? <div className="h-8 w-16 bg-slate-200 animate-pulse rounded" /> : <p className="text-3xl font-bold text-emerald-600">{activeCategories}</p>}
          </div>
          <div className="bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-outline-variant/10">
            <p className="text-xs font-bold text-on-surface-variant uppercase tracking-wider mb-2">
              Total Products
            </p>
            {loading ? <div className="h-8 w-16 bg-slate-200 animate-pulse rounded" /> : <p className="text-3xl font-bold text-on-surface">{totalProducts}</p>}
          </div>
        </div>

        {/* Categories Bento Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {loading ? (
             Array(3).fill(0).map((_, i) => (
                <div key={i} className="bg-surface-container-lowest rounded-xl p-6 shadow-sm border border-outline-variant/10 min-h-[200px]">
                   <div className="flex justify-between mb-4">
                      <div className="w-12 h-12 bg-slate-200 animate-pulse rounded-xl" />
                      <div className="w-16 h-6 bg-slate-200 animate-pulse rounded-full" />
                   </div>
                   <div className="h-6 w-32 bg-slate-200 animate-pulse rounded mb-2" />
                   <div className="h-4 w-20 bg-slate-200 animate-pulse rounded mb-6" />
                   <div className="h-2 w-full bg-slate-200 animate-pulse rounded-full" />
                </div>
             ))
          ) : (
            filteredCategories.map((cat, i) => {
              const colorTheme = colors[i % colors.length];
              const pCount = cat.products?.length || 0;
              
              return (
                <div
                  key={cat.id}
                  className="bg-surface-container-lowest rounded-xl p-6 shadow-sm border border-outline-variant/10 group hover:shadow-md transition-shadow relative overflow-hidden"
                >
                  <div className="flex justify-between items-start mb-4">
                    <div className={`w-12 h-12 rounded-xl ${colorTheme.bg} flex items-center justify-center text-2xl overflow-hidden`}>
                      {cat.image_url ? (
                         <img src={cat.image_url} alt={cat.name} className="w-full h-full object-cover" />
                      ) : (
                         <ImageIcon size={20} className={colorTheme.text} />
                      )}
                    </div>
                    <button
                      onClick={() => toggleStatus(cat)}
                      className={`text-[10px] font-bold uppercase tracking-wider px-2.5 py-1 rounded-full border cursor-pointer hover:opacity-80 transition-opacity ${
                        cat.is_active
                          ? "bg-emerald-50 border-emerald-200 text-emerald-700"
                          : "bg-slate-50 border-slate-200 text-slate-500"
                      }`}
                    >
                      {cat.is_active ? "Active" : "Draft"}
                    </button>
                  </div>
                  <h3 className="text-lg font-bold text-on-surface mb-1">
                    {cat.name}
                  </h3>
                  <p className="text-sm text-on-surface-variant mb-4">
                    {pCount} products
                  </p>
                  
                  {/* Progress Bar */}
                  <div className="mb-4">
                    <div className="h-1.5 bg-surface-container-low rounded-full overflow-hidden">
                      <div
                        className="h-full bg-gradient-to-r from-primary to-primary-container rounded-full"
                        style={{
                          width: `${Math.min((pCount / 50) * 100, 100)}%`,
                        }}
                      />
                    </div>
                  </div>
                  
                  <div className="flex items-center gap-3 pt-4 border-t border-slate-50">
                    <button onClick={() => openEditModal(cat)} className="flex-1 py-1.5 text-xs font-bold text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors flex items-center justify-center gap-1">
                      <Edit2 size={13} /> Edit
                    </button>
                    <button 
                       onClick={async () => {
                          if (pCount > 0) {
                             toast.error("Cannot delete category with associated products.");
                             return;
                          }
                          if (confirm(`Delete category?`)) {
                             const loadingToast = toast.loading("Deleting category...");
                             const { error } = await supabase.from("categories").delete().eq("id", cat.id);
                             if (error) {
                               toast.error("Failed to delete category", { id: loadingToast });
                             } else {
                               toast.success("Category deleted", { id: loadingToast });
                               fetchData();
                             }
                          }
                       }}
                       className="flex-1 py-1.5 text-xs font-bold text-red-500 hover:bg-red-50 rounded-lg transition-colors flex items-center justify-center gap-1">
                      <Trash2 size={13} /> Delete
                    </button>
                  </div>
                </div>
              );
            })
          )}

          {/* Add New Category Card */}
          <div onClick={() => {
            setEditingCatId(null);
            setNewCat({ name: "", image_url: "", sort_order: 0, is_active: true });
            setIsModalOpen(true);
          }} className="bg-surface-container-low rounded-xl p-6 shadow-sm border-2 border-dashed border-outline-variant/30 flex flex-col items-center justify-center gap-3 cursor-pointer hover:border-primary/50 hover:bg-indigo-50/30 transition-all group min-h-[200px]">
            <div className="w-12 h-12 rounded-full border-2 border-dashed border-outline-variant/40 group-hover:border-primary flex items-center justify-center transition-colors">
              <Plus size={20} className="text-on-surface-variant group-hover:text-primary transition-colors" />
            </div>
            <p className="text-sm font-semibold text-on-surface-variant group-hover:text-primary transition-colors">
              Add New Category
            </p>
          </div>
        </div>

        {/* Add Category Modal */}
        {isModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" onClick={() => !isSaving && setIsModalOpen(false)}></div>
            <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden relative z-10 animate-fade-in-up flex flex-col">
               <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center bg-slate-50">
                  <h3 className="text-lg font-bold text-slate-900">{editingCatId ? "Edit Category" : "Add Category"}</h3>
                  <button onClick={() => setIsModalOpen(false)} disabled={isSaving} className="text-slate-400 hover:text-slate-700">
                     <X size={20} />
                  </button>
               </div>
               
               <div className="p-6">
                 <form id="catForm" onSubmit={handleSaveCategory} className="space-y-4">
                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">Category Name</label>
                      <input required type="text" value={newCat.name} onChange={e => setNewCat({...newCat, name: e.target.value})} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none" placeholder="e.g. Electronics" />
                    </div>

                    <div className="mb-4">
                      <label className="block text-xs font-bold text-slate-700 mb-2">Category Image</label>
                      <ImageUploader 
                        folder="categories" 
                        onUpload={(url) => setNewCat({...newCat, image_url: url})} 
                        existingUrl={newCat.image_url} 
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">Sort Order (0-100)</label>
                      <input required type="number" min="0" value={newCat.sort_order} onChange={e => setNewCat({...newCat, sort_order: parseInt(e.target.value) || 0})} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none" />
                    </div>

                    <div className="flex items-center gap-2 mt-2">
                       <input type="checkbox" id="isActive" checked={newCat.is_active} onChange={e => setNewCat({...newCat, is_active: e.target.checked})} className="rounded text-indigo-600 focus:ring-indigo-500 disabled:opacity-50" />
                       <label htmlFor="isActive" className="text-sm font-semibold text-slate-700">Set as active</label>
                    </div>
                 </form>
               </div>
               
               <div className="px-6 py-4 border-t border-slate-100 flex justify-end gap-3 bg-slate-50">
                 <button type="button" onClick={() => setIsModalOpen(false)} disabled={isSaving} className="px-4 py-2 rounded-lg text-sm font-bold text-slate-600 hover:bg-slate-200 transition-colors">
                   Cancel
                 </button>
                 <button type="submit" form="catForm" disabled={isSaving} className="px-4 py-2 rounded-lg text-sm font-bold text-white bg-indigo-600 hover:bg-indigo-700 transition-colors disabled:opacity-70">
                   {isSaving ? "Saving..." : "Save Category"}
                 </button>
               </div>
            </div>
          </div>
        )}

      </main>
    </>
  );
}
