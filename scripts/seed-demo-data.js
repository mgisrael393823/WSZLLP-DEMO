/**
 * Seed Demo Database with Sample Data
 * This script populates the demo Supabase project with realistic sample data
 * for client demonstrations.
 */

import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load demo environment
dotenv.config({ path: join(__dirname, '..', '.env.demo') });

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ Missing Supabase credentials in .env.demo');
  console.error('Please update .env.demo with your demo project credentials');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Sample demo data
const DEMO_DATA = {
  // Demo user will be created via Supabase Auth UI
  demoEmail: 'demo@wszllp.com',
  demoPassword: 'DemoPassword123!',

  // Sample cases
  cases: [
    {
      id: 'a1234567-89ab-cdef-0123-456789abcdef',
      plaintiff: 'ABC Property Management LLC',
      defendant: 'John Smith',
      address: '123 Main St, Chicago, IL 60601',
      status: 'Filed',
      intakedate: new Date('2025-01-15').toISOString(),
    },
    {
      id: 'b2345678-9abc-def0-1234-56789abcdef0',
      plaintiff: 'XYZ Apartments Inc',
      defendant: 'Jane Doe',
      address: '456 Oak Ave, Wheaton, IL 60187',
      status: 'Hearing Scheduled',
      intakedate: new Date('2025-01-20').toISOString(),
    },
    {
      id: 'c3456789-abcd-ef01-2345-6789abcdef01',
      plaintiff: 'Riverside Properties LLC',
      defendant: 'Robert Johnson',
      address: '789 River Rd, Waukegan, IL 60085',
      status: 'Judgment Entered',
      intakedate: new Date('2025-01-10').toISOString(),
    },
  ],

  // Sample contacts
  contacts: [
    {
      name: 'John Smith',
      email: 'john.smith@example.com',
      phone: '555-0101',
      role: 'Client',
      company: null,
      address: '123 Main St, Chicago, IL',
      notes: 'Defendant in DEMO-2025-001',
    },
    {
      name: 'Jane Doe',
      email: 'jane.doe@example.com',
      phone: '555-0102',
      role: 'Client',
      company: null,
      address: '456 Oak Ave, Wheaton, IL',
      notes: 'Defendant in DEMO-2025-002',
    },
    {
      name: 'Michael Williams',
      email: 'mwilliams@abcpm.com',
      phone: '555-0201',
      role: 'PM',
      company: 'ABC Property Management LLC',
      address: '789 Business Blvd, Chicago, IL',
      notes: 'Property Manager for ABC Properties',
    },
  ],
};

async function seedDemoData() {
  console.log('🌱 Starting demo data seed...\n');

  try {
    // Step 1: Create demo user
    console.log('Step 1: Creating demo user...');
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: DEMO_DATA.demoEmail,
      password: DEMO_DATA.demoPassword,
      email_confirm: true,
    });

    if (authError && authError.code !== 'email_exists' && !authError.message.includes('already registered')) {
      throw authError;
    }

    const demoUserId = authData?.user?.id || (await getUserId(DEMO_DATA.demoEmail));
    console.log(`✅ Demo user: ${DEMO_DATA.demoEmail} (ID: ${demoUserId})\n`);

    // Step 2: Seed contacts
    console.log('Step 2: Seeding contacts...');
    const { data: contacts, error: contactsError } = await supabase
      .from('contacts')
      .insert(DEMO_DATA.contacts)
      .select();

    if (contactsError) throw contactsError;
    console.log(`✅ Created ${contacts.length} contacts\n`);

    // Step 3: Seed cases
    console.log('Step 3: Seeding cases...');
    const { data: cases, error: casesError } = await supabase
      .from('cases')
      .insert(DEMO_DATA.cases)
      .select();

    if (casesError) throw casesError;
    console.log(`✅ Created ${cases.length} cases\n`);

    // Step 4: Create sample hearings
    console.log('Step 4: Creating sample hearings...');
    const hearings = [
      {
        id: 'd4567890-bcde-f012-3456-789abcdef012',
        case_id: cases[1].id, // Jane Doe case
        hearing_date: new Date('2025-02-15T10:00:00').toISOString(),
        court_name: 'Wheaton Courthouse - Room 204',
        participants: ['Jane Doe', 'Attorney Smith'],
        outcome: null,
      },
    ];

    const { data: hearingsData, error: hearingsError } = await supabase
      .from('hearings')
      .insert(hearings)
      .select();

    if (hearingsError) throw hearingsError;
    console.log(`✅ Created ${hearingsData.length} hearing(s)\n`);

    // Success summary
    console.log('═══════════════════════════════════════════');
    console.log('✅ Demo data seeded successfully!');
    console.log('═══════════════════════════════════════════');
    console.log('\nDemo Credentials:');
    console.log(`  Email: ${DEMO_DATA.demoEmail}`);
    console.log(`  Password: ${DEMO_DATA.demoPassword}`);
    console.log('\nData Summary:');
    console.log(`  Cases: ${cases.length}`);
    console.log(`  Contacts: ${contacts.length}`);
    console.log(`  Hearings: ${hearingsData.length}`);
    console.log('\n⚠️  Store these credentials securely for client demos!');
    console.log('═══════════════════════════════════════════\n');

  } catch (error) {
    console.error('❌ Error seeding demo data:', error);
    process.exit(1);
  }
}

async function getUserId(email) {
  const { data, error } = await supabase.auth.admin.listUsers();
  if (error) throw error;

  const user = data.users.find(u => u.email === email);
  if (!user) throw new Error(`User with email ${email} not found`);

  return user.id;
}

// Run the seed
seedDemoData();
