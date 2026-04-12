"use client";

import { Download, UserPlus, MoreVertical, RefreshCw, Edit2, Trash2, X } from "lucide-react";
import { useEffect, useState, useMemo } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase/client";
import toast from "react-hot-toast";

export default function UsersPage() {
  const router = useRouter();
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // Filters
  const [searchQuery, setSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingUserId, setEditingUserId] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [editProfile, setEditProfile] = useState({ full_name: "", role: "user" });

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);

    const { data: profiles, error } = await supabase
      .from("profiles")
      .select("id, full_name, email, avatar_url, created_at")
      .order("created_at", { ascending: false });

    if (error) {
      toast.error(`Database Error: ${error.message} - Please run the SQL fix script.`);
      console.error("profiles fetch error:", error);
      setLoading(false);
      return;
    }

    const { data: orders } = await supabase
      .from("orders")
      .select("user_id, total, status, created_at, delivery_address");

    const countMap: Record<string, number> = {};
    const spendMap: Record<string, number> = {};
    const recentOrderMap: Record<string, any> = {};

    (orders || []).forEach((o) => {
      countMap[o.user_id] = (countMap[o.user_id] || 0) + 1;
      
      if (o.status === "DELIVERED") {
        spendMap[o.user_id] = (spendMap[o.user_id] || 0) + (o.total || 0);
      }

      const currRecent = recentOrderMap[o.user_id];
      if (
        !currRecent ||
        new Date(o.created_at).getTime() > new Date(currRecent.created_at).getTime()
      ) {
        recentOrderMap[o.user_id] = o;
      }
    });

    const formatted = (profiles || []).map((p) => {
      const recentOrder = recentOrderMap[p.id];
      let location = "Unknown Location";

      if (
        recentOrder &&
        recentOrder.delivery_address &&
        recentOrder.delivery_address.city
      ) {
        location = `${recentOrder.delivery_address.city}, ${
          recentOrder.delivery_address.state || "Unknown"
        }`;
      }

      return {
        ...p,
        order_count: countMap[p.id] || 0,
        total_spent: spendMap[p.id] || 0,
        location,
      };
    });

    setUsers(formatted);
    setLoading(false);
  };

  const openEditModal = (user: any) => {
     setEditingUserId(user.id);
     setEditProfile({
        full_name: user.full_name || "",
        role: user.role || "user"
     });
     setIsModalOpen(true);
  };

  const handleSaveProfile = async (e: React.FormEvent) => {
     e.preventDefault();
     if (!editingUserId) return;
     
     setIsSaving(true);
     const loadingToast = toast.loading("Updating profile...");
     
     const { error } = await supabase.from("profiles").update({
        full_name: editProfile.full_name,
        role: editProfile.role
     }).eq("id", editingUserId);
     
     setIsSaving(false);
     
     if (error) {
        toast.error("Failed to update profile", { id: loadingToast });
     } else {
        toast.success("Profile updated", { id: loadingToast });
        setIsModalOpen(false);
        fetchData();
     }
  };

  const filteredUsers = useMemo(() => {
     let result = users;
     if (searchQuery) {
        const q = searchQuery.toLowerCase();
        result = result.filter(u => 
           (u.full_name || "").toLowerCase().includes(q) || 
           (u.email || "").toLowerCase().includes(q) ||
           (u.id || "").toLowerCase().includes(q)
        );
     }
     return result;
  }, [users, searchQuery]);

  const totalPages = Math.ceil(filteredUsers.length / itemsPerPage) || 1;
  const paginatedUsers = filteredUsers.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);



  return (
    <>
      <header className="sticky top-0 w-full z-40 bg-white/80 backdrop-blur-xl border-b border-slate-100 flex justify-between items-center h-16 px-8">
        <div className="flex items-center gap-4 flex-1">
          <div className="relative w-full max-w-md">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="lucide lucide-search absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <input
              type="text"
              placeholder="Search users by name, email or ID..."
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
              Users Management
            </h1>
            <p className="text-sm text-on-surface-variant mt-1">
              Manage, filter and review your e-commerce customer base.
            </p>
          </div>
          <div className="flex gap-3">
            <button className="flex items-center gap-2 px-4 py-2 rounded-xl bg-surface-container-highest text-on-surface text-sm font-semibold transition-all hover:brightness-95">
              <Download size={16} />
              Export CSV
            </button>
            <button className="flex items-center gap-2 px-5 py-2 rounded-xl bg-gradient-to-br from-primary to-primary-container text-white text-sm font-semibold shadow-lg shadow-primary/10 transition-all hover:shadow-primary/20">
              <UserPlus size={16} />
              Invite User
            </button>
          </div>
        </div>

        <div className="bg-surface-container-lowest rounded-xl p-4 mb-6 flex flex-wrap items-center gap-4 shadow-sm">
          <div className="flex-1 flex gap-4">
            <div className="min-w-[180px]">
              <label className="block text-[10px] font-bold text-on-surface-variant uppercase mb-1 px-1">
                Filter by City
              </label>
              <select disabled className="w-full border border-slate-200 bg-surface-container-low rounded-lg text-sm px-3 py-2 text-on-surface opacity-50">
                <option>All Cities (Coming soon)</option>
              </select>
            </div>
            <div className="min-w-[180px]">
              <label className="block text-[10px] font-bold text-on-surface-variant uppercase mb-1 px-1">
                User Status
              </label>
              <select disabled className="w-full border border-slate-200 bg-surface-container-low rounded-lg text-sm px-3 py-2 text-on-surface opacity-50">
                <option>All Status</option>
              </select>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <span className="text-xs text-on-surface-variant font-medium">
              {filteredUsers.length} Users found
            </span>
            <button onClick={() => fetchData()} className="p-2 rounded-lg hover:bg-slate-100 text-slate-500 transition-colors">
              <RefreshCw size={16} className={loading ? "animate-spin" : ""} />
            </button>
          </div>
        </div>

        <div className="bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
             <table className="w-full text-left border-collapse">
               <thead>
                 <tr className="bg-surface-container-high/50 border-b border-slate-100">
                   {["User", "Contact Info", "Location", "Orders", "Total Spent", "Joined", ""].map((h, i) => (
                     <th key={h} className={`px-6 py-4 text-[11px] font-bold text-on-surface-variant uppercase tracking-wider ${i === 3 ? "text-center" : ""}`}>
                       {h}
                     </th>
                   ))}
                 </tr>
               </thead>
               <tbody>
                 {loading ? (
                    Array(5).fill(0).map((_, i) => (
                       <tr key={`sk-${i}`} className={i % 2 === 0 ? "bg-white" : "bg-[#f7f9ff]"}>
                          <td className="px-6 py-4"><div className="flex gap-3"><div className="w-10 h-10 rounded-full bg-slate-200 animate-pulse" /><div className="h-8 w-24 rounded bg-slate-200 animate-pulse" /></div></td>
                          <td className="px-6 py-4"><div className="h-8 w-32 rounded bg-slate-200 animate-pulse" /></td>
                          <td className="px-6 py-4"><div className="h-4 w-20 rounded bg-slate-200 animate-pulse" /></td>
                          <td className="px-6 py-4"><div className="h-6 w-8 rounded-full bg-slate-200 animate-pulse mx-auto" /></td>
                          <td className="px-6 py-4"><div className="h-4 w-16 rounded bg-slate-200 animate-pulse" /></td>
                          <td className="px-6 py-4"><div className="h-6 w-16 rounded-full bg-slate-200 animate-pulse" /></td>
                          <td className="px-6 py-4"></td>
                       </tr>
                    ))
                 ) : paginatedUsers.length === 0 ? (
                    <tr><td colSpan={7} className="text-center py-8 text-sm text-slate-500">No users found.</td></tr>
                 ) : (
                   paginatedUsers.map((user, rowIdx) => (
                     <tr 
                       key={user.id} 
                       onClick={() => router.push(`/users/${user.id}`)}
                       className={`group hover:bg-slate-50 transition-colors cursor-pointer ${rowIdx % 2 === 0 ? "bg-white" : "bg-[#f7f9ff]"}`}
                     >
                       <td className="px-6 py-4">
                         <div className="flex items-center gap-3">
                           {user.avatar_url ? (
                              <img src={user.avatar_url} alt="Avatar" className="w-10 h-10 rounded-full object-cover ring-2 ring-white shrink-0 shadow-sm" />
                           ) : (
                              <div className="w-10 h-10 rounded-full bg-indigo-100 flex items-center justify-center text-xs font-bold text-indigo-700 ring-2 ring-white shrink-0">
                                {user.full_name ? user.full_name.split(" ").map((n: string) => n[0]).join("") : "?"}
                              </div>
                           )}
                           <div>
                             <p className="text-sm font-bold text-on-surface line-clamp-1 max-w-[150px]">{user.full_name || "Unknown"}</p>
                             <p className="text-[10px] text-on-surface-variant bg-slate-100 px-1.5 py-0.5 rounded inline-block mt-1">ID: {user.id.substring(0, 8).toUpperCase()}</p>
                           </div>
                         </div>
                       </td>
                       <td className="px-6 py-4">
                         <div className="flex flex-col">
                           <span className="text-xs font-medium text-slate-900 line-clamp-1">{user.email || "No email"}</span>
                         </div>
                       </td>
                       <td className="px-6 py-4"><span className="text-xs text-slate-700 whitespace-nowrap">{user.location}</span></td>
                       <td className="px-6 py-4 text-center">
                         <span className="text-xs font-medium px-3 py-1 bg-indigo-50 text-indigo-700 rounded-full border border-indigo-100">
                           {user.order_count} order{user.order_count !== 1 ? 's' : ''}
                         </span>
                       </td>
                       <td className="px-6 py-4">
                         <span className="text-sm font-bold text-slate-800">₹{user.total_spent.toFixed(2)}</span>
                       </td>
                       <td className="px-6 py-4">
                         <span className="text-[11px] text-slate-500 font-medium whitespace-nowrap">
                           {new Date(user.created_at).toLocaleDateString('en-IN', { month: 'short', year: 'numeric' })}
                         </span>
                       </td>
                       <td className="px-6 py-4 text-right relative group/menu" onClick={(e) => e.stopPropagation()}>
                         <button className="p-2 hover:bg-slate-200 rounded-lg transition-all text-slate-500">
                           <MoreVertical size={16} />
                         </button>
                         <div className="absolute right-0 mt-2 w-48 bg-white border border-slate-100 rounded-xl shadow-xl opacity-0 invisible group-hover/menu:opacity-100 group-hover/menu:visible transition-all z-10 flex flex-col overflow-hidden">
                            <button onClick={() => openEditModal(user)} className="px-4 py-2.5 text-left text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2">
                               <Edit2 size={16} className="text-slate-400" /> Edit Profile
                            </button>
                            <button 
                               onClick={async () => {
                                  if (confirm("Delete user profile?")) {
                                     const loadingToast = toast.loading("Deleting profile...");
                                     const { error } = await supabase.from("profiles").delete().eq("id", user.id);
                                     if (error) toast.error("Failed to delete", { id: loadingToast });
                                     else { toast.success("Profile deleted", { id: loadingToast }); fetchData(); }
                                  }
                               }}
                               className="px-4 py-2.5 text-left text-sm text-red-600 hover:bg-red-50 flex items-center gap-2 border-t border-slate-50"
                            >
                               <Trash2 size={16} /> Delete Profile
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
            <span className="text-xs text-on-surface-variant font-medium">Page {currentPage} of {totalPages}</span>
            <div className="flex gap-2">
              <button onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1} className="px-3 py-1 rounded-lg border border-outline-variant/30 text-xs font-bold disabled:opacity-50 hover:bg-white transition-colors bg-surface-container-low">Previous</button>
              <button onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages} className="px-3 py-1 rounded-lg bg-white border border-outline-variant/30 text-xs font-bold shadow-sm hover:bg-surface-container-low disabled:opacity-50">Next</button>
            </div>
          </div>
        </div>
      </main>

      {isModalOpen && (
         <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" onClick={() => !isSaving && setIsModalOpen(false)}></div>
            <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden relative z-10 flex flex-col">
               <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center bg-slate-50">
                  <h3 className="text-lg font-bold text-slate-900">Edit Profile</h3>
                  <button onClick={() => setIsModalOpen(false)} disabled={isSaving} className="text-slate-400 hover:text-slate-700"><X size={20} /></button>
               </div>
               <form onSubmit={handleSaveProfile} className="p-6">
                  <div className="space-y-4">
                     <div>
                        <label className="block text-sm font-semibold text-slate-700 mb-1.5">Full Name</label>
                        <input type="text" required className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl font-medium text-slate-800 focus:bg-white focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/20 transition-all outline-none" value={editProfile.full_name} onChange={(e) => setEditProfile({...editProfile, full_name: e.target.value})} />
                     </div>
                     <div>
                        <label className="block text-sm font-semibold text-slate-700 mb-1.5">Role</label>
                        <select className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl font-medium text-slate-800 focus:bg-white focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/20 transition-all outline-none" value={editProfile.role} onChange={(e) => setEditProfile({...editProfile, role: e.target.value})}>
                           <option value="admin">Admin</option>
                           <option value="user">User</option>
                        </select>
                     </div>
                  </div>
                  <div className="mt-8 flex items-center justify-end gap-3 pt-6 border-t border-slate-100">
                     <button type="button" onClick={() => setIsModalOpen(false)} disabled={isSaving} className="px-6 py-2.5 rounded-xl font-semibold text-slate-600 hover:bg-slate-100 transition-colors">Cancel</button>
                     <button type="submit" disabled={isSaving} className="px-6 py-2.5 rounded-xl font-semibold bg-indigo-600 text-white hover:bg-indigo-700 disabled:opacity-50 transition-colors shadow-lg shadow-indigo-600/20">{isSaving ? "Saving..." : "Save Changes"}</button>
                  </div>
               </form>
            </div>
         </div>
      )}
    </>
  );
}
