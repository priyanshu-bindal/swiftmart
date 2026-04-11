"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  ShoppingCart,
  Package,
  Tag,
  Zap,
  Image as ImageIcon,
  Users,
  Truck,
  Ticket,
  BarChart2,
  Settings,
  PanelLeftClose,
  PanelLeftOpen,
} from "lucide-react";
import { useSidebar } from "@/context/SidebarContext";

const navItems = [
  { label: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { label: "Orders", href: "/orders", icon: ShoppingCart },
  { label: "Products", href: "/products", icon: Package },
  { label: "Categories", href: "/categories", icon: Tag },
  { label: "Deals", href: "/deals/flash-deals", icon: Zap },
  { label: "Banners", href: "/banners", icon: ImageIcon },
  { label: "Users", href: "/users", icon: Users },
  { label: "Delivery", href: "/delivery", icon: Truck },
  { label: "Coupons", href: "/coupons", icon: Ticket },
  { label: "Analytics", href: "/analytics", icon: BarChart2 },
  { label: "Settings", href: "/settings", icon: Settings },
];

export default function Sidebar() {
  const pathname = usePathname();
  const { collapsed, toggle } = useSidebar();

  return (
    <aside
      className={`
        h-screen fixed left-0 top-0 overflow-y-auto overflow-x-hidden
        bg-slate-50 flex flex-col py-6 z-50 no-scrollbar
        border-r border-slate-100
        transition-[width] duration-300 ease-in-out
        ${collapsed ? "w-[72px]" : "w-64"}
      `}
    >
      {/* Logo + Hamburger */}
      <div className="px-4 mb-8 flex items-center justify-between gap-2 shrink-0">
        {/* Logo mark — always visible */}
        <div className="flex items-center gap-3 overflow-hidden min-w-0">
          <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center text-white shrink-0">
            <span className="text-sm font-bold">S</span>
          </div>

          {/* Text fades + slides out when collapsed */}
          <div
            className={`
              flex flex-col overflow-hidden whitespace-nowrap
              transition-all duration-300 ease-in-out
              ${collapsed ? "w-0 opacity-0" : "w-40 opacity-100"}
            `}
          >
            <span className="text-lg font-bold text-indigo-700 leading-tight">
              SwiftMart
            </span>
            <span className="text-[10px] font-medium text-slate-500 uppercase tracking-widest">
              Management Suite
            </span>
          </div>
        </div>

        {/* Hamburger toggle */}
        <button
          onClick={toggle}
          title={collapsed ? "Expand sidebar" : "Collapse sidebar"}
          className="shrink-0 p-1.5 rounded-lg text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 transition-colors"
        >
          {collapsed ? (
            <PanelLeftOpen size={18} strokeWidth={2} />
          ) : (
            <PanelLeftClose size={18} strokeWidth={2} />
          )}
        </button>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 space-y-0.5">
        {navItems.map(({ label, href, icon: Icon }) => {
          const isActive = pathname === href;
          return (
            <Link
              key={href}
              href={href}
              title={collapsed ? label : undefined}
              className={`
                flex items-center gap-3 px-2.5 py-2.5 text-sm font-medium
                rounded-lg transition-colors duration-200
                ${
                  isActive
                    ? "text-indigo-700 bg-indigo-50 font-semibold border-r-4 border-indigo-600"
                    : "text-slate-500 hover:text-indigo-600 hover:bg-slate-100"
                }
                ${collapsed ? "justify-center" : ""}
              `}
            >
              <Icon
                size={18}
                className={`shrink-0 transition-colors ${
                  isActive ? "text-indigo-700" : "text-slate-400"
                }`}
                strokeWidth={isActive ? 2.5 : 2}
              />

              {/* Label slides away when collapsed */}
              <span
                className={`
                  overflow-hidden whitespace-nowrap transition-all duration-300 ease-in-out
                  ${collapsed ? "w-0 opacity-0" : "w-auto opacity-100"}
                `}
              >
                {label}
              </span>
            </Link>
          );
        })}
      </nav>

      {/* Bottom user section */}
      <div className="px-3 mt-auto pt-6 shrink-0">
        <div
          className={`
            p-3 rounded-xl bg-indigo-50 border border-indigo-100 flex items-center gap-3
            transition-all duration-300 relative group
            ${collapsed ? "justify-center" : ""}
          `}
        >
          <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center text-white text-xs font-bold shrink-0">
            A
          </div>

          <div
            className={`
              flex flex-col overflow-hidden
              transition-all duration-300 ease-in-out
              ${collapsed ? "w-0 opacity-0" : "w-36 opacity-100"}
            `}
          >
            <span className="text-xs font-bold text-on-surface truncate">Admin</span>
            <span className="text-[10px] text-on-surface-variant truncate">Super Admin</span>
          </div>
          
          {/* Logout Button */}
          <button
            onClick={async () => {
              const { supabase } = await import("@/lib/supabase/client");
              await supabase.auth.signOut();
              window.location.href = "/login";
            }}
            className={`
              absolute right-3 p-1.5 rounded-md text-slate-400 hover:text-red-600 hover:bg-red-50 transition-colors
              ${collapsed ? "hidden" : "opacity-0 group-hover:opacity-100"}
            `}
            title="Log out"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="lucide lucide-log-out"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/></svg>
          </button>
        </div>
      </div>
    </aside>
  );
}
