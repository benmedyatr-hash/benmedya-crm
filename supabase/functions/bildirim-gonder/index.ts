// BenMedya CRM — telefon bildirimi gönderici (Supabase Edge Function: bildirim-gonder)
// Her dakika pg_cron çağırır; uygulama da "Deneme bildirimi"nde çağırır.
// Ne gönderileceğine veritabanı karar verir (public.bildirim_kuyrugu) — burası yalnız iletir.
// Herkese açık çağrılabilir ("Verify JWT" KAPALI): yalnız zamanı gelmiş bildirimleri bir kez gönderir, veri döndürmez.
import postgres from 'npm:postgres@3.4.5';
import webpush from 'npm:web-push@3.6.7';

const sql = postgres(Deno.env.get('SUPABASE_DB_URL')!, { prepare: false, max: 1 });
const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

async function anahtarlar() {
  let [a] = await sql`select acik, gizli from public.bildirim_anahtar where id = 1`;
  if (!a) {
    const k = webpush.generateVAPIDKeys();
    await sql`insert into public.bildirim_anahtar (id, acik, gizli) values (1, ${k.publicKey}, ${k.privateKey}) on conflict (id) do nothing`;
    [a] = await sql`select acik, gizli from public.bildirim_anahtar where id = 1`;
  }
  return a;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  try {
    const a = await anahtarlar();
    webpush.setVapidDetails('https://crm.benmedya.com', a.acik, a.gizli);
    const liste = await sql`select x as j from public.bildirim_kuyrugu() as x`;
    let gitti = 0, olu = 0, hata = 0;
    await Promise.all(liste.map(async ({ j }) => {
      try {
        await webpush.sendNotification(
          { endpoint: j.endpoint, keys: { p256dh: j.p256dh, auth: j.auth } },
          JSON.stringify({ baslik: j.baslik, govde: j.govde, etiket: j.etiket, url: '/app/' }),
          { TTL: 3600, urgency: 'high' },
        );
        gitti++;
      } catch (e) {
        const kod = (e as { statusCode?: number }).statusCode;
        if (kod === 404 || kod === 410) { olu++; await sql`delete from public.bildirim_abonelik where endpoint = ${j.endpoint}`; }
        else { hata++; console.error('gonderilemedi', kod, (e as Error).message); }
      }
    }));
    return new Response(JSON.stringify({ ok: true, gitti, olu, hata }), { headers: { ...CORS, 'Content-Type': 'application/json' } });
  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ ok: false }), { status: 500, headers: { ...CORS, 'Content-Type': 'application/json' } });
  }
});
