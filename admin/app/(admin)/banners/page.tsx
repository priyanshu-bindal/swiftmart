"use client";

import { Plus, Edit2, Trash2 } from "lucide-react";
import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase/client";
import toast from "react-hot-toast";
import { useRouter } from "next/navigation";

function BannerPreview({ banner }: { banner: any }) {
  return (
    <div className="aspect-[21/9] rounded-lg overflow-hidden bg-gradient-to-r from-indigo-600 to-indigo-400 flex items-center justify-center relative bg-cover bg-center" style={banner.image_url ? { backgroundImage: `url(${banner.image_url})` } : {}}>
      <div className="absolute inset-0 bg-black/30"></div>
      <div className="absolute top-2 left-2 px-2 py-1 bg-black/40 backdrop-blur-md rounded-md text-[10px] font-bold text-white uppercase tracking-wider">
        Sort: {banner.sort_order}
      </div>
      <div className="text-white text-center relative z-10 px-4">
        <p className="text-xl font-black drop-shadow-md">{banner.title}</p>
        <p className="text-white/90 text-xs font-bold drop-shadow-md">{banner.subtitle}</p>
      </div>
    </div>
  );
}

export default function BannersPage() {
  const [banners, setBanners] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // Filters
  const [searchQuery, setSearchQuery] = useState("");

  const router = useRouter();

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    const { data } = await supabase
      .from("banners")
      .select("*")
      .order("sort_order", { ascending: true });

    if (data) setBanners(data);
    setLoading(false);
  };

  const handleToggleActive = async (id: string, currentStatus: boolean) => {
     const loadingToast = toast.loading("Updating status...");
     setBanners(prev => prev.map(b => b.id === id ? { ...b, is_active: !currentStatus } : b));
     const { error } = await supabase.from("banners").update({ is_active: !currentStatus }).eq("id", id);
     if (error) {
       toast.error("Failed to update status", { id: loadingToast });
       fetchData(); // revert optimistic update
     } else {
       toast.success("Status updated", { id: loadingToast });
     }
  };

  const filteredBanners = banners.filter(b => 
     searchQuery ? b.title.toLowerCase().includes(searchQuery.toLowerCase()) : true
  );

  return (
    <>
      <header className="sticky top-0 w-full z-40 bg-white/80 backdrop-blur-xl border-b border-slate-100 flex justify-between items-center h-16 px-8">
        <div className="flex items-center gap-4 flex-1">
          <div className="relative w-full max-w-md">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="lucide lucide-search absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <input
              type="text"
              placeholder="Search banners..."
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

      <main className="p-8 bg-surface min-h-screen">
        <div className="flex justify-between items-end mb-8">
          <div>
            <h1 className="text-2xl font-bold text-on-surface tracking-tight">
              Banner Management
            </h1>
            <p className="text-sm text-on-surface-variant mt-1">
              Configure and schedule marketing assets across your storefront.
            </p>
          </div>
          <button onClick={() => router.push('/banners/new')} className="bg-gradient-to-br from-primary to-primary-container text-white px-5 py-2.5 rounded-xl font-semibold flex items-center gap-2 shadow-lg shadow-indigo-500/10 hover:shadow-indigo-500/20 transition-all">
            <Plus size={18} />
            Create Banner
          </button>
        </div>

        {/* Banner Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {loading ? (
             Array(3).fill(0).map((_, i) => (
                <div key={i} className="bg-surface-container-lowest rounded-xl p-4 shadow-sm border border-outline-variant/15 flex flex-col gap-4">
                   <div className="aspect-[21/9] bg-slate-200 animate-pulse rounded-lg" />
                   <div className="h-4 w-3/4 bg-slate-200 animate-pulse rounded" />
                   <div className="h-6 w-full bg-slate-200 animate-pulse rounded" />
                </div>
             ))
          ) : (
            filteredBanners.map((banner) => (
              <div
                key={banner.id}
                className="bg-surface-container-lowest rounded-xl p-4 shadow-sm border border-outline-variant/15 flex flex-col gap-4"
              >
                <BannerPreview banner={banner} />

                <div className="flex justify-between items-start">
                  <div>
                    <h3 className="font-semibold text-on-surface line-clamp-1">{banner.title}</h3>
                    <p className="text-xs text-on-surface-variant line-clamp-1">
                      {banner.subtitle}
                    </p>
                  </div>
                  <div className="flex items-center gap-2 shrink-0 ml-2">
                    <span
                      className={`w-2 h-2 rounded-full ${
                        banner.is_active ? "bg-emerald-500" : "bg-slate-300"
                      }`}
                    />
                    <span
                      className={`text-[10px] font-bold uppercase tracking-widest ${
                        banner.is_active ? "text-emerald-600" : "text-slate-400"
                      }`}
                    >
                      {banner.is_active ? "Active" : "Disabled"}
                    </span>
                  </div>
                </div>

                <div className="flex items-center justify-between pt-2 border-t border-slate-50">
                  <div className="flex items-center gap-3">
                    <button onClick={() => router.push(`/banners/${banner.id}/edit`)} className="text-indigo-600 hover:bg-indigo-50 p-1.5 rounded-lg transition-colors">
                      <Edit2 size={18} />
                    </button>
                    <button 
                       onClick={async () => {
                          if (confirm("Delete banner?")) {
                             const loadingToast = toast.loading("Deleting banner...");
                             const { error } = await supabase.from("banners").delete().eq("id", banner.id);
                             if (error) {
                                toast.error("Failed to delete banner", { id: loadingToast });
                             } else {
                                toast.success("Banner deleted", { id: loadingToast });
                                fetchData();
                             }
                          }
                       }}
                       className="text-error hover:bg-error-container/20 p-1.5 rounded-lg transition-colors"
                    >
                      <Trash2 size={18} />
                    </button>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      className="sr-only peer"
                      checked={banner.is_active}
                      onChange={() => handleToggleActive(banner.id, banner.is_active)}
                    />
                    <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary" />
                  </label>
                </div>
              </div>
            ))
          )}

          {/* Add Banner Card */}
          <div onClick={() => router.push('/banners/new')} className="bg-surface-container-low rounded-xl border-2 border-dashed border-outline-variant/30 flex flex-col items-center justify-center gap-3 cursor-pointer hover:border-primary/50 hover:bg-indigo-50/30 transition-all group min-h-[240px]">
            <div className="w-12 h-12 rounded-full border-2 border-dashed border-outline-variant/40 group-hover:border-primary flex items-center justify-center transition-colors">
              <Plus size={20} className="text-on-surface-variant group-hover:text-primary transition-colors" />
            </div>
            <p className="text-sm font-semibold text-on-surface-variant group-hover:text-primary transition-colors">
              Create New Banner
            </p>
          </div>
        </div>

      </main>
    </>
  );
}
