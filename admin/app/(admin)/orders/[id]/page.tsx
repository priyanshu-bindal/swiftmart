"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase/client";
import toast from "react-hot-toast";
import { ArrowLeft, Printer, CheckCircle, Package, Truck, Mail, Phone, MapPin, X } from "lucide-react";
import React from 'react';

export default function OrderDetailsPage({ params }: { params: Promise<{ id: string }> }) {
  const router = useRouter();
  
  // Next.js 15 requires awaiting params
  const [orderId, setOrderId] = useState<string | null>(null);
  
  useEffect(() => {
    params.then((p) => setOrderId(p.id));
  }, [params]);

  const [order, setOrder] = useState<any>(null);
  const [items, setItems] = useState<any[]>([]);
  const [profile, setProfile] = useState<any>(null);
  const [currentStatus, setCurrentStatus] = useState("");
  const [loading, setLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (!orderId) return;

    const fetchOrderDetails = async () => {
      setLoading(true);
      // 1. Fetch order
      const { data: orderData, error } = await supabase
        .from('orders')
        .select('*')
        .eq('id', orderId)
        .single();
      
      if (error) console.error("Supabase order fetch error:", error);

      if (orderData) {
        setOrder(orderData);
        setCurrentStatus(orderData.status);

        // 2. Fetch order items separately since there's no FK to products
        const { data: itemsData } = await supabase
          .from('order_items')
          .select('*')
          .eq('order_id', orderId);
        
        if (itemsData) setItems(itemsData);

        // 3. Fetch customer profile separately since there's no strict FK relation to orders
        if (orderData.user_id) {
          const { data: profileData } = await supabase
            .from('profiles')
            .select('full_name, email, avatar_url, created_at')
            .eq('id', orderData.user_id)
            .single();
          if (profileData) setProfile(profileData);
        }
      }
      setLoading(false);
    };

    fetchOrderDetails();
  }, [orderId]);

  const handleStatusUpdate = async (newStatus: string) => {
    setIsSaving(true);
    let dbStatus = newStatus.toUpperCase();
    if (newStatus === 'pending') dbStatus = 'PREPARING';
    if (newStatus === 'in_transit') dbStatus = 'OUT_FOR_DELIVERY';

    const { error } = await supabase
      .from('orders')
      .update({ status: dbStatus })
      .eq('id', orderId);
    
    if (!error) {
      setCurrentStatus(dbStatus);
      toast.success('Order status updated!');
    } else {
      toast.error('Update failed. Try again.');
    }
    setIsSaving(false);
  };

  const handlePrintInvoice = () => {
    window.print();
  };

  const getStatusLabel = (status: string) => {
    if (!status) return 'Unknown';
    const labels: Record<string, string> = {
      pending: 'Pending',
      preparing: 'Pending',
      confirmed: 'Confirmed', 
      in_transit: 'Out for Delivery',
      out_for_delivery: 'Out for Delivery',
      delivered: 'Delivered',
      cancelled: 'Cancelled'
    };
    return labels[status.toLowerCase()] || status;
  };

  const getStatusStyles = (status: string) => {
    if (!status) return "bg-slate-100 text-slate-700";
    switch(status.toLowerCase()) {
      case 'pending':
      case 'preparing': return "bg-amber-100 text-amber-700";
      case 'confirmed': return "bg-blue-100 text-blue-700";
      case 'in_transit':
      case 'out_for_delivery': return "bg-purple-100 text-purple-700";
      case 'delivered': return "bg-emerald-100 text-emerald-700";
      case 'cancelled': return "bg-red-100 text-red-700";
      default: return "bg-slate-100 text-slate-700";
    }
  };

  const isStepReached = (currentStatus: string, step: string) => {
    if (!currentStatus) return false;
    const orderSteps = ['pending', 'confirmed', 'in_transit', 'delivered'];
    const cs = currentStatus.toLowerCase();
    const norm = cs === 'preparing' ? 'pending' : (cs === 'out_for_delivery' ? 'in_transit' : cs);
    return orderSteps.indexOf(norm) >= orderSteps.indexOf(step.toLowerCase());
  };

  const isStepCurrent = (currentStatus: string, step: string) => {
    if (!currentStatus) return false;
    const cs = currentStatus.toLowerCase();
    const norm = cs === 'preparing' ? 'pending' : (cs === 'out_for_delivery' ? 'in_transit' : cs);
    return norm === step.toLowerCase();
  };

  const formatDate = (dateString: string) => {
    if (!dateString) return "";
    const d = new Date(dateString);
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    let hours = d.getHours();
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    hours = hours ? hours : 12;
    const minutes = d.getMinutes().toString().padStart(2, '0');
    return `${d.getDate()} ${months[d.getMonth()]}, ${d.getFullYear()} at ${hours}:${minutes} ${ampm}`;
  };

  if (loading || !orderId) {
    return (
      <div className="p-8 flex items-center justify-center min-h-screen relative bg-[#f8f9fc]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  if (!order) {
    return (
      <div className="p-8 bg-[#f8f9fc] min-h-screen">
        <button onClick={() => router.push('/orders')} className="flex items-center text-slate-500 hover:text-slate-800 transition-colors mb-6 font-medium">
          <ArrowLeft size={16} className="mr-2" /> Back to Orders
        </button>
        <div className="text-center py-20 bg-white rounded-2xl shadow-sm border border-slate-100">
          <h2 className="text-xl font-bold text-slate-800">Order not found</h2>
          <p className="text-slate-500 mt-2">The order you are looking for does not exist.</p>
        </div>
      </div>
    );
  }

  const address = typeof order.delivery_address === 'string'
    ? JSON.parse(order.delivery_address)
    : order.delivery_address || {};

  const fullAddressStr = `${address.house_no || ''} ${address.street || ''}, ${address.city || ''}, ${address.state || ''} ${address.pincode || ''}`.trim();
  const mapsApiKey = process.env.NEXT_PUBLIC_MAPS_API_KEY || "";

  const normStatus = (() => {
    const cs = currentStatus?.toLowerCase() || '';
    return cs === 'preparing' ? 'pending' : (cs === 'out_for_delivery' ? 'in_transit' : cs);
  })();

  const memberSinceStr = profile?.created_at 
    ? new Date(profile.created_at).toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
    : 'Unknown';

  const avatarInitial = profile?.full_name ? profile.full_name[0].toUpperCase() : "?";

  return (
    <div className="min-h-screen bg-[#f8f9fc]">
      {/* Print CSS */}
      <style dangerouslySetInnerHTML={{__html: `
        @media print {
          .btn-contact-customer, .update-status-card, .btn-print, .back-btn { display: none !important; }
          body { background: white !important; }
          main { padding: 0 !important; margin: 0 !important; }
          .admin-sidebar { display: none !important; }
          .admin-topbar { display: none !important; }
          @page { margin: 1cm; }
        }
      `}} />

      <main className="p-8 max-w-7xl mx-auto order-detail-page">
        {/* SECTION 1 - Header */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
          <div>
            <button onClick={() => router.push('/orders')} className="back-btn flex items-center text-slate-500 hover:text-indigo-600 transition-colors mb-4 font-semibold text-sm">
              <ArrowLeft size={16} className="mr-2" /> Back to Orders
            </button>
            <p className="text-xs font-extrabold text-slate-400 uppercase tracking-widest mb-1">TRANSACTION REFERENCE</p>
            <div className="flex items-center gap-3">
              <h1 className="text-3xl font-black text-[#1a1f5e] uppercase">#ORD-{order.id.substring(0, 8)}</h1>
              <span className={`px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider ${getStatusStyles(currentStatus)}`}>
                {getStatusLabel(currentStatus)}
              </span>
            </div>
            <p className="text-slate-500 mt-2 font-medium">Placed on {formatDate(order.created_at)}</p>
          </div>

          <div className="header-actions flex items-center gap-3">
             <div className="flex items-center gap-2">
                <select
                  value={normStatus}
                  onChange={(e) => handleStatusUpdate(e.target.value)}
                  disabled={isSaving}
                  className={`appearance-none px-4 py-2.5 rounded-xl text-sm font-bold uppercase tracking-wider outline-none cursor-pointer border-2 transition-all ${getStatusStyles(currentStatus)} focus:ring-4 focus:ring-indigo-500/20 disabled:opacity-50 disabled:cursor-not-allowed`}
                >
                  <option value="pending">Pending</option>
                  <option value="confirmed">Confirmed</option>
                  <option value="in_transit">Out for Delivery</option>
                  <option value="delivered">Delivered</option>
                  <option value="cancelled">Cancelled</option>
                </select>
             </div>
            <button 
              onClick={handlePrintInvoice}
              className="btn-print flex items-center gap-2 px-5 py-2.5 bg-white border border-slate-200 rounded-xl text-slate-700 font-bold hover:bg-slate-50 hover:border-slate-300 shadow-sm transition-all"
            >
              <Printer size={18} />
              Print Invoice
            </button>
          </div>
        </div>

        <div className="flex flex-col lg:flex-row gap-6">
          
          {/* LEFT COLUMN - flex: 2 */}
          <div className="flex-[2] flex flex-col gap-6">
            
            {/* SECTION 2 - Order Items */}
            <div className="bg-white rounded-[16px] border border-gray-200 p-6 shadow-sm overflow-hidden">
              <h2 className="text-lg font-bold text-[#1a1f5e] mb-4">Items Ordered</h2>
              <div className="overflow-x-auto">
                <table className="w-full text-left">
                  <thead className="border-b border-gray-100">
                    <tr>
                      <th className="pb-3 text-xs font-extrabold text-slate-400 uppercase tracking-wider">Product</th>
                      <th className="pb-3 text-xs font-extrabold text-slate-400 uppercase tracking-wider">Price</th>
                      <th className="pb-3 text-xs font-extrabold text-slate-400 uppercase tracking-wider">Qty</th>
                      <th className="pb-3 text-xs font-extrabold text-slate-400 uppercase tracking-wider text-right">Subtotal</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-50">
                    {items.length === 0 ? (
                      <tr><td colSpan={4} className="py-4 text-center text-slate-500">No items found.</td></tr>
                    ) : (
                      items.map((item) => (
                        <tr key={item.id}>
                          <td className="py-4 pr-4">
                            <div className="flex items-center gap-4">
                              <div className="w-14 h-14 rounded-lg bg-slate-50 border border-slate-100 flex-shrink-0 overflow-hidden">
                                {item.image_url ? (
                                  <img src={item.image_url} alt="Product" className="w-full h-full object-cover" />
                                ) : (
                                  <div className="w-full h-full flex items-center justify-center text-slate-300"><Package size={24} /></div>
                                )}
                              </div>
                              <div>
                                <p className="font-bold text-[#1a1f5e] line-clamp-2">{item.name || 'Unknown Product'}</p>
                                <p className="text-xs text-slate-400 mt-0.5">SKU: {item.product_id ? item.product_id.substring(0,8).toUpperCase() : item.id.substring(0,8).toUpperCase()} {item.unit ? `• ${item.unit}` : ''}</p>
                              </div>
                            </div>
                          </td>
                          <td className="py-4 font-semibold text-slate-700">₹{(item.unit_price || 0).toFixed(2)}</td>
                          <td className="py-4 text-slate-600 font-medium whitespace-nowrap">x {item.quantity}</td>
                          <td className="py-4 text-right">
                            <strong className="text-[#1a1f5e]">₹{((item.unit_price || 0) * (item.quantity || 1)).toFixed(2)}</strong>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* SECTION 3 - Order Timeline */}
            <div className="bg-white rounded-[16px] border border-gray-200 p-6 shadow-sm">
              <h2 className="text-lg font-bold text-[#1a1f5e] mb-6">Order Timeline</h2>
              <div className="relative pl-4 space-y-8">
                {/* Vertical Line */}
                <div className="absolute left-[27px] top-4 bottom-4 w-0.5 bg-slate-100 -z-10"></div>
                
                {[
                  { id: 'pending', label: 'Order Placed', time: order.created_at, icon: Package },
                  { id: 'confirmed', label: 'Confirmed', time: order.confirmed_at, icon: CheckCircle },
                  { id: 'in_transit', label: 'Out for Delivery', time: order.dispatched_at, icon: Truck },
                  { id: 'delivered', label: 'Delivered', time: order.delivered_at, icon: MapPin }
                ].map((step, idx) => {
                  const reached = isStepReached(currentStatus, step.id);
                  const current = isStepCurrent(currentStatus, step.id);
                  
                  // In timeline, a step is "completed" if we've reached a later step, 
                  // or if it's the final 'delivered' step and we've reached it.
                  const completed = isStepReached(currentStatus, step.id) && !current;
                  const finalDelivered = step.id === 'delivered' && current;
                  const isDone = completed || finalDelivered;

                  let dotColor = 'bg-slate-200 ring-slate-100 border-white';
                  let iconColor = 'text-slate-400';
                  let titleColor = 'text-slate-400';
                  let subLabel = `Pending ${idx > 0 ? 'previous step' : ''}`;

                  if (isDone) {
                    dotColor = 'bg-[#065f46] ring-[#d1fae5] border-[#065f46]';
                    iconColor = 'text-white';
                    titleColor = 'text-slate-800';
                    subLabel = step.time ? formatDate(step.time) : 'Completed';
                  } else if (current) {
                    dotColor = 'bg-[#4f46e5] ring-[#e0e7ff] border-[#4f46e5] shadow-lg shadow-indigo-500/30';
                    iconColor = 'text-white';
                    titleColor = 'text-[#4f46e5]';
                    subLabel = 'In progress';
                  }

                  // Force "Placed" to always show the created_at date nicely
                  if (step.id === 'pending' && step.time) {
                    subLabel = formatDate(step.time);
                  }

                  return (
                    <div key={step.id} className="flex gap-5 items-start">
                      <div className={`w-7 h-7 rounded-full flex items-center justify-center shrink-0 border-2 ring-4 ${dotColor} z-10 transition-all`}>
                        {isDone ? <CheckCircle size={14} className={iconColor} strokeWidth={3} /> : <step.icon size={12} className={iconColor} />}
                      </div>
                      <div className="flex flex-col pt-0.5">
                        <span className={`text-sm font-bold ${titleColor} transition-colors`}>{step.label}</span>
                        <span className="text-xs text-slate-500 mt-0.5">{subLabel}</span>
                      </div>
                    </div>
                  );
                })}

                {/* Cancelled Step (only if cancelled) */}
                {normStatus === 'cancelled' && (
                  <div className="flex gap-5 items-start">
                    <div className="w-7 h-7 rounded-full flex items-center justify-center shrink-0 border-2 bg-red-600 ring-red-100 border-red-600 shadow-lg shadow-red-500/30 z-10">
                      <X size={14} className="text-white" strokeWidth={3} />
                    </div>
                    <div className="flex flex-col pt-0.5">
                      <span className="text-sm font-bold text-red-600">Cancelled</span>
                      <span className="text-xs text-slate-500 mt-0.5">Order was cancelled</span>
                    </div>
                  </div>
                )}
              </div>
            </div>

          </div>

          {/* RIGHT COLUMN - flex: 1 */}
          <div className="flex-1 flex flex-col gap-6">

            {/* SECTION 4 - Customer Info */}
            <div className="bg-white rounded-[16px] border border-gray-200 p-6 shadow-sm">
              <h2 className="text-sm font-bold text-[#1a1f5e] mb-4 uppercase tracking-wider">Customer Info</h2>
              <div className="flex items-center gap-4 mb-5">
                {profile?.avatar_url ? (
                  <img src={profile.avatar_url} alt="Customer" className="w-14 h-14 rounded-full object-cover border border-slate-200 shadow-sm" />
                ) : (
                  <div className="w-14 h-14 rounded-full bg-indigo-50 border border-indigo-100 flex items-center justify-center text-xl font-black text-indigo-600">
                    {avatarInitial}
                  </div>
                )}
                <div>
                  <p className="font-bold text-slate-800 text-lg">{profile?.full_name || 'Guest User'}</p>
                  <p className="text-xs text-slate-500 font-medium">Member since {memberSinceStr}</p>
                </div>
              </div>
              <div className="flex flex-col gap-3">
                <div className="flex items-center gap-3 px-3 py-2.5 bg-slate-50 rounded-xl border border-slate-100">
                  <Mail size={16} className="text-slate-400" />
                  <span className="text-sm text-slate-700 font-medium truncate">{profile?.email || 'No email'}</span>
                </div>
                <div className="flex items-center gap-3 px-3 py-2.5 bg-slate-50 rounded-xl border border-slate-100">
                  <Phone size={16} className="text-slate-400" />
                  <span className="text-sm text-slate-700 font-medium">{profile?.phone || 'Not provided'}</span>
                </div>
                <button 
                  className="btn-contact-customer w-full mt-2 py-2.5 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-bold text-sm rounded-xl border border-indigo-100 transition-colors flex items-center justify-center gap-2"
                  onClick={() => {
                    if (profile?.phone) {
                      window.location.href = `tel:${profile.phone}`;
                    } else if (profile?.email) {
                      window.location.href = `mailto:${profile.email}`;
                    } else {
                      toast.error('No contact info available');
                    }
                  }}
                >
                  💬 Contact Customer
                </button>
              </div>
            </div>

                      {/* SECTION 6 - Payment Summary */}
            <div className="bg-white rounded-[16px] border border-gray-200 p-6 shadow-sm">
              <h2 className="text-sm font-bold text-[#1a1f5e] mb-4 uppercase tracking-wider">Payment Summary</h2>
              <div className="flex flex-col gap-3 mb-5">
                <div className="flex justify-between">
                  <span className="text-sm font-semibold text-slate-500">Subtotal</span>
                  <span className="text-sm font-bold text-slate-800">₹{(order.subtotal || 0).toFixed(2)}</span>
                </div>
                {(order.discount_amount > 0) && (
                  <div className="flex justify-between">
                    <span className="text-sm font-semibold text-slate-500">Discount</span>
                    <span className="text-sm font-bold text-[#065f46]">-₹{(order.discount_amount || 0).toFixed(2)}</span>
                  </div>
                )}
                <div className="flex justify-between">
                  <span className="text-sm font-semibold text-slate-500">Delivery Fee</span>
                  <span className="text-sm font-bold text-slate-800">
                    {order.delivery_fee > 0 ? `₹${order.delivery_fee.toFixed(2)}` : <span className="text-emerald-600">FREE</span>}
                  </span>
                </div>
              </div>
              
              <div className="h-px w-full bg-slate-100 mb-4" />
              
              <div className="flex justify-between items-center mb-4">
                <span className="text-base font-bold text-slate-900">Grand Total</span>
                <span className="text-2xl font-black text-[#4f46e5]">₹{(order.total || 0).toFixed(2)}</span>
              </div>

              <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-emerald-50 text-emerald-700 rounded-lg text-xs font-bold border border-emerald-100">
                <CheckCircle size={14} />
                Paid via {order.payment_method || 'Online'}
              </div>
            </div>

            {/* SECTION 5 - Delivery Address */}
            <div className="bg-white rounded-[16px] border border-gray-200 p-6 shadow-sm">
              <h2 className="text-sm font-bold text-[#1a1f5e] mb-4 uppercase tracking-wider">Delivery Address</h2>
              
              <div className="mb-4">
                <p className="text-sm text-slate-700 font-medium leading-relaxed">
                  {address.house_no && `${address.house_no}, `}{address.street && `${address.street}`}<br/>
                  {address.city && `${address.city}, `}{address.state && `${address.state} `}
                  <span className="font-bold">{address.pincode || ''}</span>
                </p>
                {!address.house_no && !address.street && (
                  <p className="text-sm text-slate-500 italic">No detailed address available.</p>
                )}
              </div>

              <div className="w-full h-[140px] bg-slate-100 rounded-xl border border-slate-200 overflow-hidden flex items-center justify-center relative">
                {mapsApiKey ? (
                  <img 
                    src={`https://maps.googleapis.com/maps/api/staticmap?center=${encodeURIComponent(fullAddressStr)}&zoom=14&size=400x160&key=${mapsApiKey}`}
                    alt="Map"
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="flex flex-col items-center justify-center text-slate-400">
                    <MapPin size={32} className="mb-2 opacity-50" />
                    <span className="text-xs font-medium opacity-70">Maps API key missing</span>
                  </div>
                )}
              </div>
            </div>

  



          </div>
        </div>
      </main>
    </div>
  );
}
