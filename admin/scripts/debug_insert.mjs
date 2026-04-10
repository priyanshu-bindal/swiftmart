import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://wfbxhuuvstahijtwsraf.supabase.co',
  'sb_publishable_0z4xzVT3isqJsF46-efEVw_QUwNAzx4'
);

// We need the service role key to insert without RLS matching our own UUID, or we just insert and see what error we get.
// Actually, since RLS is 'true' for all authenticated, we need to sign in, or we just fetch if it's there. 
// Let's test insert anonymously – it will fail RLS, but if it fails schema, we'll see schema errors first usually.
async function run() {
  const payload = {
    name: "Test Category " + Date.now(),
    image_url: "https://example.com/test.png",
    sort_order: 10,
    is_active: true
  };
  const { data, error } = await supabase.from('categories').insert([payload]);
  console.log("INSERT RESULT:", { data, error });
}

run();
