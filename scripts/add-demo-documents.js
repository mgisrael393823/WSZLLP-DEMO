import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '..', '.env.demo') });

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function addDocuments() {
  console.log('📄 Adding demo documents...\n');

  // Get existing cases
  const { data: cases, error: casesError } = await supabase
    .from('cases')
    .select('id, plaintiff, defendant')
    .order('createdat', { ascending: true })
    .limit(3);

  if (casesError) throw casesError;

  if (cases.length === 0) {
    console.log('❌ No cases found. Please run seed-demo-data.js first.');
    process.exit(1);
  }

  console.log(`Found ${cases.length} existing cases`);

  const documents = [
    {
      case_id: cases[0].id,
      type: 'Complaint',
      file_url: 'https://example.com/documents/complaint-001.pdf',
      original_filename: 'Eviction_Complaint_Smith.pdf',
      status: 'Served',
      service_date: new Date('2025-01-18T00:00:00').toISOString(),
    },
    {
      case_id: cases[0].id,
      type: 'Summons',
      file_url: 'https://example.com/documents/summons-001.pdf',
      original_filename: 'Summons_Smith.pdf',
      status: 'Served',
      service_date: new Date('2025-01-18T00:00:00').toISOString(),
    },
    {
      case_id: cases[1].id,
      type: 'Complaint',
      file_url: 'https://example.com/documents/complaint-002.pdf',
      original_filename: 'Eviction_Complaint_Doe.pdf',
      status: 'Pending',
      service_date: null,
    },
    {
      case_id: cases[1].id,
      type: 'Affidavit',
      file_url: 'https://example.com/documents/affidavit-002.pdf',
      original_filename: 'Service_Affidavit_Doe.pdf',
      status: 'Pending',
      service_date: null,
    },
    {
      case_id: cases[2].id,
      type: 'Order',
      file_url: 'https://example.com/documents/order-003.pdf',
      original_filename: 'Court_Order_Judgment.pdf',
      status: 'Served',
      service_date: new Date('2025-01-12T00:00:00').toISOString(),
    },
    {
      case_id: cases[2].id,
      type: 'Motion',
      file_url: 'https://example.com/documents/motion-003.pdf',
      original_filename: 'Motion_for_Summary_Judgment.pdf',
      status: 'Served',
      service_date: new Date('2025-01-11T00:00:00').toISOString(),
    },
  ];

  const { data: documentsData, error: documentsError } = await supabase
    .from('documents')
    .insert(documents)
    .select();

  if (documentsError) throw documentsError;

  console.log(`✅ Created ${documentsData.length} document(s)\n`);
  console.log('Documents added to cases:');
  cases.forEach((c, i) => {
    const docCount = documents.filter(d => d.case_id === c.id).length;
    console.log(`  - ${c.plaintiff} v. ${c.defendant}: ${docCount} documents`);
  });
}

addDocuments().catch(error => {
  console.error('❌ Error:', error);
  process.exit(1);
});
