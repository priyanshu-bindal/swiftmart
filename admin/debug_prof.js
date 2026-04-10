const { createClient } = require('@supabase/supabase-js');
const supabase = createClient('https://wfbxhuuvstahijtwsraf.supabase.co', 'sb_publishable_0z4xzVT3isqJsF46-efEVw_QUwNAzx4');

async function run() {
  const { data } = await supabase.from('profiles').select('*').limit(1);
  console.log(data);
}

run();
