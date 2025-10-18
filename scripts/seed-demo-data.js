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
      caseNumber: 'DEMO-2025-001',
      plaintiffName: 'ABC Property Management LLC',
      defendantName: 'John Smith',
      caseType: 'Eviction',
      status: 'Filed',
      filingDate: new Date('2025-01-15').toISOString(),
      county: 'Cook County',
      courtLocation: 'Chicago - Richard J. Daley Center',
    },
    {
      caseNumber: 'DEMO-2025-002',
      plaintiffName: 'XYZ Apartments Inc',
      defendantName: 'Jane Doe',
      caseType: 'Eviction',
      status: 'Hearing Scheduled',
      filingDate: new Date('2025-01-20').toISOString(),
      county: 'DuPage County',
      courtLocation: 'Wheaton Courthouse',
    },
    {
      caseNumber: 'DEMO-2025-003',
      plaintiffName: 'Riverside Properties LLC',
      defendantName: 'Robert Johnson',
      caseType: 'Eviction',
      status: 'Judgment Entered',
      filingDate: new Date('2025-01-10').toISOString(),
      county: 'Lake County',
      courtLocation: 'Waukegan Courthouse',
    },
  ],

  // Sample contacts
  contacts: [
    {
      firstName: 'John',
      lastName: 'Smith',
      email: 'john.smith@example.com',
      phone: '555-0101',
      contactType: 'Defendant',
      company: null,
    },
    {
      firstName: 'Jane',
      lastName: 'Doe',
      email: 'jane.doe@example.com',
      phone: '555-0102',
      contactType: 'Defendant',
      company: null,
    },
    {
      firstName: 'Michael',
      lastName: 'Williams',
      email: 'mwilliams@abcpm.com',
      phone: '555-0201',
      contactType: 'Property Manager',
      company: 'ABC Property Management LLC',
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

    if (authError && !authError.message.includes('already registered')) {
      throw authError;
    }

    const demoUserId = authData?.user?.id || (await getUserId(DEMO_DATA.demoEmail));
    console.log(`✅ Demo user: ${DEMO_DATA.demoEmail} (ID: ${demoUserId})\n`);

    // Step 2: Seed contacts
    console.log('Step 2: Seeding contacts...');
    const contactsToInsert = DEMO_DATA.contacts.map(contact => ({
      ...contact,
      user_id: demoUserId,
    }));

    const { data: contacts, error: contactsError } = await supabase
      .from('contacts')
      .insert(contactsToInsert)
      .select();

    if (contactsError) throw contactsError;
    console.log(`✅ Created ${contacts.length} contacts\n`);

    // Step 3: Seed cases
    console.log('Step 3: Seeding cases...');
    const casesToInsert = DEMO_DATA.cases.map(caseData => ({
      ...caseData,
      user_id: demoUserId,
    }));

    const { data: cases, error: casesError } = await supabase
      .from('cases')
      .insert(casesToInsert)
      .select();

    if (casesError) throw casesError;
    console.log(`✅ Created ${cases.length} cases\n`);

    // Step 4: Create sample hearings
    console.log('Step 4: Creating sample hearings...');
    const hearings = [
      {
        case_id: cases[1].id, // Jane Doe case
        hearing_date: new Date('2025-02-15T10:00:00').toISOString(),
        hearing_type: 'Initial Hearing',
        location: 'Wheaton Courthouse - Room 204',
        user_id: demoUserId,
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
  const { data, error } = await supabase
    .from('auth.users')
    .select('id')
    .eq('email', email)
    .single();

  if (error) throw error;
  return data.id;
}

// Run the seed
seedDemoData();
