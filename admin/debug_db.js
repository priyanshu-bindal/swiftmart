const { createClient } = require('@supabase/supabase-js');
const supabase = createClient('https://wfbxhuuvstahijtwsraf.supabase.co', 'sb_publishable_0z4xzVT3isqJsF46-efEVw_QUwNAzx4');

async function run() {
  const { data, error } = await supabase.from('orders').select('*');
  console.log('DB count:', data?.length);
  console.log('Error:', error);
}

run();
