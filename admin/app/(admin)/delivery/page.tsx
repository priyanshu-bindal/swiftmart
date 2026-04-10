import TopBar from "@/components/TopBar";
import { Map, UserPlus, Star, Plus, Minus } from "lucide-react";

const partners = [
  {
    name: "Marcus Chen",
    phone: "+1 234 567 890",
    zone: "Downtown Core",
    status: "On Delivery",
    statusColor: "bg-secondary-container text-on-secondary-container",
    ordersToday: 24,
    rating: 4.9,
  },
  {
    name: "Sarah Johnson",
    phone: "+1 234 567 891",
    zone: "East Riverside",
    status: "Online",
    statusColor: "bg-emerald-100 text-emerald-700",
    ordersToday: 18,
    rating: 4.7,
  },
  {
    name: "David Miller",
    phone: "+1 234 567 892",
    zone: "North Heights",
    status: "Offline",
    statusColor: "bg-slate-100 text-slate-500",
    ordersToday: 12,
    rating: 4.5,
  },
];

export default function DeliveryPage() {
  return (
    <>
      <TopBar placeholder="Search delivery partners..." />
      <main className="p-8 bg-surface min-h-screen">
        <div className="flex justify-between items-end mb-8">
          <div>
            <h1 className="text-3xl font-bold tracking-tight text-on-surface">
              Delivery Partners
            </h1>
            <p className="text-on-surface-variant mt-1 font-medium">
              Manage and track your active fleet in real-time.
            </p>
          </div>
          <div className="flex gap-3">
            <button className="flex items-center px-4 py-2.5 bg-surface-container-lowest text-on-surface font-semibold rounded-xl shadow-sm hover:bg-surface-container-high transition-all border border-outline-variant/10">
              <Map size={18} className="mr-2" />
              Toggle Map View
            </button>
            <button className="flex items-center px-4 py-2.5 bg-gradient-to-br from-primary to-primary-container text-white font-semibold rounded-xl shadow-md hover:opacity-90 transition-all">
              <UserPlus size={18} className="mr-2" />
              Onboard Partner
            </button>
          </div>
        </div>

        {/* Stats Bento */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          {[
            {
              label: "Active Fleet",
              value: "142",
              badge: "+12%",
              badgeColor: "text-emerald-600 bg-emerald-50",
            },
            {
              label: "On Delivery",
              value: "89",
              badge: "63% of fleet",
              badgeColor: "text-on-surface-variant",
              highlight: true,
            },
            { label: "Avg. Rating", value: "4.8", badge: "⭐⭐⭐" },
            {
              label: "Delayed Orders",
              value: "4",
              badge: "Critical",
              badgeColor: "text-error bg-error-container/20",
              valueColor: "text-error",
            },
          ].map(({ label, value, badge, badgeColor, highlight, valueColor }) => (
            <div
              key={label}
              className={`bg-surface-container-lowest p-6 rounded-xl shadow-sm flex flex-col justify-between ${
                highlight ? "border-b-4 border-indigo-500" : ""
              }`}
            >
              <span className="text-xs font-semibold text-on-surface-variant tracking-wider uppercase">
                {label}
              </span>
              <div className="flex items-end justify-between mt-4">
                <span
                  className={`text-3xl font-bold ${
                    valueColor || "text-on-surface"
                  }`}
                >
                  {value}
                </span>
                <span
                  className={`text-xs font-bold px-2 py-1 rounded ${
                    badgeColor || "text-on-surface-variant"
                  }`}
                >
                  {badge}
                </span>
              </div>
            </div>
          ))}
        </div>

        {/* Main Layout: Table + Map */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Partners Table */}
          <div className="lg:col-span-2 bg-surface-container-lowest rounded-xl shadow-sm overflow-hidden">
            <div className="px-6 py-4 flex justify-between items-center border-b border-slate-50">
              <h3 className="font-bold text-lg text-on-surface">
                Partner Directory
              </h3>
              <div className="flex items-center gap-2">
                <span className="text-xs font-semibold text-on-surface-variant">
                  Filter by:
                </span>
                <select className="text-xs border-none bg-surface-container-low rounded-lg focus:ring-primary px-2 py-1.5">
                  <option>All Zones</option>
                  <option>Downtown</option>
                  <option>Suburbs</option>
                </select>
              </div>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left">
                <thead className="bg-surface-container-low">
                  <tr>
                    {["Partner", "Zone", "Status", "Orders Today", "Rating"].map(
                      (h) => (
                        <th
                          key={h}
                          className="px-6 py-4 text-xs font-bold text-on-surface-variant uppercase tracking-wider"
                        >
                          {h}
                        </th>
                      )
                    )}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-50">
                  {partners.map((p) => (
                    <tr
                      key={p.name}
                      className="hover:bg-slate-50 transition-colors"
                    >
                      <td className="px-6 py-4">
                        <div className="flex items-center">
                          <div className="h-10 w-10 rounded-full overflow-hidden mr-3 bg-indigo-100 flex items-center justify-center text-indigo-700 font-bold text-sm">
                            {p.name
                              .split(" ")
                              .map((n) => n[0])
                              .join("")}
                          </div>
                          <div>
                            <div className="font-bold text-sm text-on-surface">
                              {p.name}
                            </div>
                            <div className="text-xs text-on-surface-variant">
                              {p.phone}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="text-sm font-medium text-on-surface">
                          {p.zone}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <span
                          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold ${p.statusColor}`}
                        >
                          {p.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-center">
                        <span className="text-sm font-bold">{p.ordersToday}</span>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center text-secondary">
                          <Star
                            size={14}
                            className="fill-secondary text-secondary mr-1"
                          />
                          <span className="text-sm font-bold text-on-surface">
                            {p.rating}
                          </span>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className="px-6 py-4 bg-slate-50 flex justify-between items-center">
              <span className="text-xs font-semibold text-on-surface-variant">
                Showing 3 of 142 partners
              </span>
              <div className="flex gap-1">
                <button className="px-3 py-1 bg-white border border-slate-200 rounded-lg text-xs font-bold hover:bg-slate-50">
                  Prev
                </button>
                <button className="px-3 py-1 bg-primary text-white rounded-lg text-xs font-bold">
                  1
                </button>
                <button className="px-3 py-1 bg-white border border-slate-200 rounded-lg text-xs font-bold hover:bg-slate-50">
                  2
                </button>
                <button className="px-3 py-1 bg-white border border-slate-200 rounded-lg text-xs font-bold hover:bg-slate-50">
                  Next
                </button>
              </div>
            </div>
          </div>

          {/* Map + Stats */}
          <div className="lg:col-span-1 flex flex-col gap-6">
            {/* Live Map */}
            <div className="bg-surface-container-lowest rounded-xl shadow-sm overflow-hidden flex-1">
              <div className="px-6 py-4 border-b border-slate-50">
                <h3 className="font-bold text-lg text-on-surface">
                  Live Fleet Map
                </h3>
                <p className="text-xs text-on-surface-variant">
                  Real-time GPS tracking
                </p>
              </div>
              <div className="relative bg-slate-200 h-64 overflow-hidden">
                {/* Grid-based map mockup */}
                <div className="absolute inset-0 opacity-20">
                  <div className="grid grid-cols-6 h-full">
                    {Array.from({ length: 6 }).map((_, i) => (
                      <div key={i} className="border-r border-slate-400 h-full" />
                    ))}
                  </div>
                  <div className="absolute inset-0 grid grid-rows-6">
                    {Array.from({ length: 6 }).map((_, i) => (
                      <div key={i} className="border-b border-slate-400 w-full" />
                    ))}
                  </div>
                </div>

                {/* Map Pins */}
                <div className="absolute top-1/4 left-1/3">
                  <div className="relative flex items-center justify-center">
                    <div className="absolute w-8 h-8 bg-primary/20 rounded-full animate-ping" />
                    <div className="relative z-10 w-4 h-4 bg-primary border-2 border-white rounded-full shadow-lg" />
                    <div className="absolute -top-10 left-1/2 -translate-x-1/2 glass-panel px-2 py-1 rounded shadow-md whitespace-nowrap">
                      <span className="text-[10px] font-bold text-primary">
                        Marcus (On Delivery)
                      </span>
                    </div>
                  </div>
                </div>
                <div className="absolute bottom-1/3 right-1/4">
                  <div className="relative flex items-center justify-center">
                    <div className="w-4 h-4 bg-emerald-500 border-2 border-white rounded-full shadow-lg" />
                    <div className="absolute -top-10 left-1/2 -translate-x-1/2 glass-panel px-2 py-1 rounded shadow-md whitespace-nowrap">
                      <span className="text-[10px] font-bold text-emerald-600">
                        Sarah (Idle)
                      </span>
                    </div>
                  </div>
                </div>

                {/* Map Controls */}
                <div className="absolute right-4 bottom-4 flex flex-col gap-2">
                  <button className="p-2 bg-white rounded-lg shadow-md hover:bg-slate-50">
                    <Plus size={16} className="text-slate-700" />
                  </button>
                  <button className="p-2 bg-white rounded-lg shadow-md hover:bg-slate-50">
                    <Minus size={16} className="text-slate-700" />
                  </button>
                </div>
              </div>
            </div>

            {/* Stats Card */}
            <div className="bg-indigo-900 rounded-xl p-6 text-white shadow-xl relative overflow-hidden">
              <div className="relative z-10">
                <div className="flex justify-between items-start mb-4">
                  <div className="bg-white/20 p-2 rounded-lg">
                    <span className="text-lg">🕐</span>
                  </div>
                  <span className="text-xs font-bold uppercase tracking-widest text-indigo-200">
                    Last 24h
                  </span>
                </div>
                <h4 className="text-2xl font-bold mb-1">2,481</h4>
                <p className="text-indigo-200 text-sm">Completed Deliveries</p>
              </div>
              <div className="absolute -bottom-10 -right-10 w-40 h-40 bg-white/5 rounded-full blur-3xl" />
            </div>
          </div>
        </div>
      </main>
    </>
  );
}
