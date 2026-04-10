import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://wfbxhuuvstahijtwsraf.supabase.co',
  'sb_publishable_0z4xzVT3isqJsF46-efEVw_QUwNAzx4'
);

async function run() {
  const { data, error } = await supabase.from('categories').select('*');
  console.log('Categories:', data, error);

  const { data: prodData } = await supabase.from('products').select('id, name, category_id');
  console.log('Products:', prodData);
}

run();
