"use client";

import React, { useState, useCallback, useRef } from "react";
import { Upload, X, Loader2, Image as ImageIcon } from "lucide-react";
import { supabase } from "@/lib/supabase/client";

interface ImageUploaderProps {
  onUpload: (url: string) => void;
  folder: string;
  existingUrl?: string;
}

export default function ImageUploader({ onUpload, folder, existingUrl }: ImageUploaderProps) {
  const [isUploading, setIsUploading] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");
  const [isDragOver, setIsDragOver] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFile = async (file: File) => {
    setErrorMsg("");
    
    // 1. Validate file type and size
    const validTypes = ["image/png", "image/jpeg", "image/jpg", "image/gif", "image/webp"];
    if (!validTypes.includes(file.type)) {
      setErrorMsg("Invalid file type. Please upload PNG, JPG, GIF, or WEBP.");
      return;
    }

    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
      setErrorMsg("File is too large. Maximum size is 10MB.");
      return;
    }

    // 2. Upload to Supabase Storage
    setIsUploading(true);
    try {
      const fileExt = file.name.split(".").pop();
      const fileName = `${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;
      const filePath = `${folder}/${fileName}`;

      const { data, error } = await supabase.storage
        .from("swiftmart-images")
        .upload(filePath, file, { upsert: true });

      if (error) throw error;

      // 4. Get public URL
      const { data: urlData } = supabase.storage
        .from("swiftmart-images")
        .getPublicUrl(filePath);

      // 5. Call onUpload
      onUpload(urlData.publicUrl);
    } catch (err: any) {
      console.error("Upload error:", err);
      setErrorMsg(err.message || "Failed to upload image. Does the 'swiftmart-images' bucket exist?");
    } finally {
      setIsUploading(false);
    }
  };

  const onDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(true);
  }, []);

  const onDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
  }, []);

  const onDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      handleFile(e.dataTransfer.files[0]);
      e.dataTransfer.clearData();
    }
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      handleFile(e.target.files[0]);
    }
  };

  const handleRemove = (e: React.MouseEvent) => {
    e.stopPropagation();
    onUpload(""); // Call with empty string to clear
    if (fileInputRef.current) {
       fileInputRef.current.value = ''; // Reset input to allow same file upload again
    }
  };

  // Click handler to open file dialog
  const handleClick = () => {
    if (!isUploading) {
      fileInputRef.current?.click();
    }
  };

  return (
    <div className="w-full flex flex-col gap-2">
      <div 
        onClick={handleClick}
        onDragOver={onDragOver}
        onDragLeave={onDragLeave}
        onDrop={onDrop}
        className={`w-full aspect-[4/3] rounded-2xl border-2 border-dashed flex flex-col items-center justify-center text-center p-6 relative overflow-hidden transition-all duration-200 ${
          isUploading ? "bg-slate-50 border-slate-200 cursor-not-allowed" :
          isDragOver ? "bg-indigo-50/50 border-[#5D3FD3] scale-[0.98]" : 
          "bg-[#F3F4F6] border-[#CCCDD2] hover:border-[#5D3FD3] cursor-pointer"
        }`}
      >
        <input 
          type="file" 
          ref={fileInputRef} 
          className="hidden" 
          accept="image/png, image/jpeg, image/jpg, image/gif, image/webp" 
          onChange={handleChange} 
        />
        
        {isUploading ? (
          <div className="flex flex-col items-center gap-3 text-[#5D3FD3]">
            <Loader2 className="w-8 h-8 animate-spin" />
            <p className="font-bold text-sm">Uploading...</p>
          </div>
        ) : existingUrl ? (
          <div className="absolute inset-0 group">
            <img 
              src={existingUrl} 
              alt="Uploaded preview" 
              className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105" 
            />
            <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity text-white backdrop-blur-[2px]">
              <div className="flex flex-col items-center gap-2">
                <Upload size={24} className="mb-1" />
                <p className="font-bold text-sm">Change Image</p>
              </div>
            </div>
            <button 
              onClick={handleRemove}
              className="absolute top-3 right-3 p-1.5 bg-red-500 hover:bg-red-600 text-white rounded-lg shadow-lg opacity-0 group-hover:opacity-100 transition-all z-10"
              title="Remove image"
            >
              <X size={16} strokeWidth={3} />
            </button>
          </div>
        ) : (
          <>
            <div className={`w-12 h-12 rounded-full flex items-center justify-center shadow-sm mb-3 transition-colors ${isDragOver ? "bg-indigo-100 text-indigo-600" : "bg-white text-slate-600"}`}>
              <Upload size={20} strokeWidth={2.5} />
            </div>
            <p className={`font-bold pb-1 text-sm ${isDragOver ? "text-indigo-600" : "text-slate-800"}`}>
              {isDragOver ? "Drop image here" : "Click or drag image here"}
            </p>
            <p className="text-[11px] text-slate-500 font-medium leading-relaxed max-w-[140px]">
              PNG, JPG, WEBP, GIF up to 10MB
            </p>
          </>
        )}
      </div>
      
      {errorMsg ? (
        <p className="text-xs font-bold text-red-500 mt-1 px-1">{errorMsg}</p>
      ) : existingUrl && !isUploading ? (
         <div className="flex bg-emerald-50 text-emerald-700 px-3 py-2 rounded-lg text-xs font-bold mt-1 max-w-full overflow-hidden">
            <span className="truncate">✓ Image ready</span>
         </div>
      ) : null}
    </div>
  );
}
