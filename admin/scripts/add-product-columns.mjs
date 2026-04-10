import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://wfbxhuuvstahijtwsraf.supabase.co',
  'sb_publishable_0z4xzVT3isqJsF46-efEVw_QUwNAzx4'
);

// First, check what columns already exist
const { data, error } = await supabase.from('products').select('*').limit(1);
if (error) {
  console.error('Error fetching products:', error.message);
} else {
  console.log('Existing columns:', Object.keys(data[0] || {}));
}

// Try adding each column individually via rpc or direct update
// Since we can't run raw SQL with anon key, we'll test if columns exist
// by trying to select them
const testCols = ['sku_code', 'is_featured', 'is_flash_deal', 'is_daily_essential'];
for (const col of testCols) {
  const { error: selErr } = await supabase.from('products').select(col).limit(1);
  if (selErr) {
    console.log(`❌ Column "${col}" does NOT exist - ${selErr.message}`);
  } else {
    console.log(`✅ Column "${col}" exists`);
  }
}

console.log('\n--- If columns are missing, add them via Supabase Dashboard SQL Editor: ---');
console.log(`
ALTER TABLE products
  ADD COLUMN IF NOT EXISTS sku_code TEXT,
  ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_flash_deal BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_daily_essential BOOLEAN DEFAULT false;
`);
