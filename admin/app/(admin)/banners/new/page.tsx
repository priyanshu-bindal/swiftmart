"use client";

import { ArrowLeft, Save } from "lucide-react";
import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase/client";
import ImageUploader from "@/components/ImageUploader";
import toast from "react-hot-toast";
import { useRouter } from "next/navigation";

export default function NewBannerPage() {
  const router = useRouter();
  const [isSaving, setIsSaving] = useState(false);

  const [form, setForm] = useState({
    title: "",
    subtitle: "",
    cta_text: "",
    badge_text: "",
    destination_route: "",
    start_date: "",
    end_date: "",
    display_order: 0,
    is_active: true,
    image_url: "",
    banner_size: "full_width",
    text_alignment: "left",
    text_color: "white",
    placement_after: "top",
  });

  const [placementOptions, setPlacementOptions] = useState<any[]>([]);

  useEffect(() => {
    const fetchOptions = async () => {
      const [{ data: categories }, { data: banners }] = await Promise.all([
        supabase.from('categories').select('id, name').eq('is_active', true).order('sort_order', { ascending: true }),
        supabase.from('banners').select('id, title').eq('is_active', true).order('sort_order', { ascending: true })
      ]);

      const cats = categories || [];
      const bans = banners || [];

      const options = [
        { value: 'top', label: 'At the very top of the home screen', group: 'General' },
        ...cats.map(c => ({ value: `after_category_${c.id}`, label: `After category: ${c.name}`, group: 'After a Category' })),
        ...bans.map(b => ({ value: `after_banner_${b.id}`, label: `After banner: ${b.title}`, group: 'After a Banner' }))
      ];
      setPlacementOptions(options);
    };
    fetchOptions();
  }, []);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title || !form.image_url) {
      toast.error("Image and Title are required");
      return;
    }

    setIsSaving(true);
    const loadingToast = toast.loading("Saving banner...");

    try {
      const payload = {
        title: form.title,
        subtitle: form.subtitle,
        image_url: form.image_url,
        is_active: form.is_active,
        sort_order: form.display_order,
        banner_size: form.banner_size,
        text_alignment: form.text_alignment,
        text_color: form.text_color,
        placement_after: form.placement_after,
      };

      const { error } = await supabase.from("banners").insert([payload]);
      
      if (error) throw error;
      
      toast.success("Banner saved!", { id: loadingToast });
      setTimeout(() => {
        router.push("/banners");
      }, 1000);
      
    } catch (error: any) {
      toast.error(error.message || "An error occurred", { id: loadingToast });
      setIsSaving(false);
    }
  };

  return (
    <main className="p-8 bg-surface min-h-screen">
      {/* Header */}
      <div className="flex justify-between items-center mb-8">
        <div className="flex items-center gap-4">
          <button onClick={() => router.push("/banners")} className="p-2 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 transition-colors shadow-sm">
            <ArrowLeft size={20} className="text-slate-600" />
          </button>
          <div>
            <h1 className="text-2xl font-bold text-on-surface tracking-tight">Add New Banner</h1>
            <p className="text-sm text-on-surface-variant mt-1">Create a new promotional banner.</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={() => router.push("/banners")} className="px-5 py-2.5 text-sm font-semibold text-slate-600 bg-white border border-slate-200 hover:bg-slate-50 rounded-xl transition-colors shadow-sm">
            Discard
          </button>
          <button onClick={handleSave} disabled={isSaving} className="bg-gradient-to-br from-primary to-primary-container text-white px-6 py-2.5 rounded-xl font-semibold flex items-center gap-2 shadow-lg shadow-indigo-500/10 hover:shadow-indigo-500/20 transition-all disabled:opacity-70">
            <Save size={18} />
            {isSaving ? "Saving..." : "Save Banner"}
          </button>
        </div>
      </div>

      <div className="flex gap-8">
        {/* Left Column - 60% */}
        <div className="flex-[6] space-y-6">
          <div className="bg-white rounded-2xl shadow-sm border border-slate-100 p-6 space-y-6">
            <h2 className="text-lg font-bold text-slate-800">Banner Details</h2>
            
            <div className="grid grid-cols-2 gap-6">
              <div className="space-y-1.5 col-span-2">
                <label className="text-xs font-bold text-slate-600 uppercase tracking-wider">Banner Title *</label>
                <input
                  required
                  type="text"
                  value={form.title}
                  onChange={e => setForm({...form, title: e.target.value})}
                  placeholder="e.g. Summer Mega Sale"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                />
              </div>

              <div className="space-y-1.5 col-span-2">
                <label className="text-xs font-bold text-slate-600 uppercase tracking-wider">Subtitle</label>
                <input
                  type="text"
                  value={form.subtitle}
                  onChange={e => setForm({...form, subtitle: e.target.value})}
                  placeholder="e.g. Up to 50% Off Everything"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-600 uppercase tracking-wider">CTA Button Text</label>
                <input
                  type="text"
                  value={form.cta_text}
                  onChange={e => setForm({...form, cta_text: e.target.value})}
                  placeholder="e.g. Shop Now"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-600 uppercase tracking-wider">Badge Text</label>
                <input
                  type="text"
                  value={form.badge_text}
                  onChange={e => setForm({...form, badge_text: e.target.value})}
                  placeholder="e.g. FLASH DEAL"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                />
              </div>

              <div className="space-y-1.5 col-span-2">
                <label className="text-xs font-bold text-slate-600 uppercase tracking-wider">Destination Route</label>
                <input
                  type="text"
                  value={form.destination_route}
                  onChange={e => setForm({...form, destination_route: e.target.value})}
                  placeholder="e.g. /flash-deals"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                />
              </div>
            </div>

            <hr className="border-slate-100" />
            
            <h2 className="text-lg font-bold text-slate-800">Placement & Alignment</h2>
            <div className="grid grid-cols-2 gap-6">
              <div className="space-y-1.5 col-span-2">
                <label className="text-xs font-bold text-slate-600 uppercase tracking-wider">Place on Home Screen...</label>
                {placementOptions.length === 0 ? (
                  <div className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-4 text-sm text-slate-400 animate-pulse">
                    Loading options...
                  </div>
                ) : (
                  <select
                    value={form.placement_after}
                    onChange={e => setForm({...form, placement_after: e.target.value})}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                  >
                    <optgroup label="General">
                      {placementOptions.filter(o => o.group === 'General').map(o => (
                        <option key={o.value} value={o.value}>{o.label}</option>
                      ))}
                    </optgroup>
                    {placementOptions.filter(o => o.group === 'After a Category').length > 0 && (
                      <optgroup label="After a Category">
                        {placementOptions.filter(o => o.group === 'After a Category').map(o => (
                          <option key={o.value} value={o.value}>{o.label}</option>
                        ))}
                      </optgroup>
                    )}
                    {placementOptions.filter(o => o.group === 'After a Banner').length > 0 && (
                      <optgroup label="After a Banner">
                        {placementOptions.filter(o => o.group === 'After a Banner').map(o => (
                          <option key={o.value} value={o.value}>{o.label}</option>
                        ))}
                      </optgroup>
                    )}
                  </select>
                )}
                <p className="text-xs text-slate-400 mt-1">Select exactly which section this banner should appear beneath.</p>
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-600 uppercase tracking-wider">Banner Size</label>
                <select
                  value={form.banner_size}
                  onChange={e => setForm({...form, banner_size: e.target.value})}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                >
                  <option value="full_width">Full width banner</option>
                  <option value="half_width">Half width banner</option>
                  <option value="square">Square card</option>
                </select>
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-600 uppercase tracking-wider">Text Alignment</label>
                <div className="flex bg-slate-50 border border-slate-200 rounded-xl overflow-hidden p-1">
                  {['left', 'center', 'right'].map((align) => (
                    <button
                      key={align}
                      type="button"
                      onClick={() => setForm({...form, text_alignment: align})}
                      className={`flex-1 py-1.5 text-sm font-semibold capitalize rounded-lg transition-colors ${form.text_alignment === align ? 'bg-white text-indigo-700 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
                    >
                      {align}
                    </button>
                  ))}
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-600 uppercase tracking-wider">Text Color</label>
                <select
                  value={form.text_color}
                  onChange={e => setForm({...form, text_color: e.target.value})}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                >
                  <option value="white">White text</option>
                  <option value="dark">Dark text</option>
                </select>
              </div>
            </div>

            <hr className="border-slate-100" />
            
            <h2 className="text-lg font-bold text-slate-800">Schedule</h2>

            <div className="grid grid-cols-2 gap-6">
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-600 uppercase tracking-wider">Start Date</label>
                <input
                  type="date"
                  value={form.start_date}
                  onChange={e => setForm({...form, start_date: e.target.value})}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-600 uppercase tracking-wider">End Date</label>
                <input
                  type="date"
                  value={form.end_date}
                  onChange={e => setForm({...form, end_date: e.target.value})}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                />
              </div>
              
              <div className="space-y-1.5 pt-6 col-span-2">
                <label className="relative inline-flex items-center cursor-pointer">
                  <input 
                    type="checkbox" 
                    className="sr-only peer" 
                    checked={form.is_active}
                    onChange={e => setForm({...form, is_active: e.target.checked})}
                  />
                  <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-500"></div>
                  <span className="ml-3 text-sm font-semibold text-slate-700">Set as active</span>
                </label>
              </div>
            </div>
          </div>
        </div>

        {/* Right Column - 40% */}
        <div className="flex-[4] space-y-6">
          <div className="bg-white rounded-2xl shadow-sm border border-slate-100 p-6 space-y-4">
            <h2 className="text-lg font-bold text-slate-800">Banner Image *</h2>
            <ImageUploader 
               folder="banners" 
               onUpload={(url) => setForm({...form, image_url: url})} 
               existingUrl={form.image_url} 
            />
          </div>

          <div className="bg-white rounded-2xl shadow-sm border border-slate-100 p-6 space-y-4 flex flex-col items-center">
            <h2 className="text-lg font-bold text-slate-800 self-start">Live Preview</h2>
            <div className={`rounded-2xl overflow-hidden bg-slate-100 flex items-center justify-center relative bg-cover bg-center border border-slate-200 shadow-inner ${form.banner_size === 'full_width' ? 'w-full aspect-[21/9]' : form.banner_size === 'half_width' ? 'w-1/2 aspect-[4/3]' : 'w-2/3 aspect-square'}`} style={form.image_url ? { backgroundImage: `url(${form.image_url})` } : {}}>
              <div className="absolute inset-0 bg-black/30"></div>
              
              {form.badge_text && (
                <div className="absolute top-4 left-4 px-3 py-1 bg-gradient-to-r from-emerald-500 to-teal-500 rounded-full text-[11px] font-bold text-white uppercase tracking-wider shadow-lg max-w-[80%]">
                  <div className="truncate">{form.badge_text}</div>
                </div>
              )}

              <div className={`absolute inset-4 flex flex-col ${(form.text_alignment === 'left') ? 'items-start text-left' : (form.text_alignment === 'center') ? 'items-center text-center' : 'items-end text-right'}`}>
                <div className="mt-auto pointer-events-none w-full">
                  <h3 className={`text-2xl font-black drop-shadow-md leading-tight ${form.text_color === 'white' ? 'text-white' : 'text-slate-800'}`}>{form.title || "Banner Title"}</h3>
                  <p className={`text-sm font-bold drop-shadow-md mt-1 ${form.text_color === 'white' ? 'text-white/90' : 'text-slate-700'}`}>{form.subtitle || "Banner subtitle will appear here"}</p>
                </div>
                
                {form.cta_text && (
                  <button className={`mt-3 whitespace-nowrap bg-white text-indigo-700 px-4 py-2 rounded-lg text-xs font-bold shadow-lg hover:bg-slate-50 transition-colors relative z-10 flex-shrink-0 self-${form.text_alignment === 'left' ? 'start' : form.text_alignment === 'center' ? 'center' : 'end'}`}>
                    {form.cta_text}
                  </button>
                )}
              </div>
            </div>
            <p className="text-xs text-slate-400 text-center uppercase tracking-widest font-bold self-start mt-2">How it looks in app</p>
          </div>
        </div>
      </div>
    </main>
  );
}
