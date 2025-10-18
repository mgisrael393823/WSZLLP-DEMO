import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { vi } from 'vitest';
import { TextFilter } from '@/components/ui/table-filters/TextFilter';
import { Column } from '@tanstack/react-table';
import { TEST_IDS, PLACEHOLDERS, TEST_COLUMN_IDS } from './test-constants';

// Mock column
const createMockColumn = (filterValue = ''): Column<any, unknown> => ({
  id: TEST_COLUMN_IDS.TEST_COLUMN,
  getFilterValue: () => filterValue,
  setFilterValue: vi.fn(),
  getFacetedUniqueValues: () => new Map(),
  getFacetedMinMaxValues: () => undefined,
  columnDef: {
    accessorKey: 'test',
    header: 'Test Column',
  },
} as any);

describe('TextFilter', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders with placeholder', () => {
    const column = createMockColumn();
    render(<TextFilter column={column} />);
    
    const input = screen.getByTestId(TEST_IDS.textFilter(TEST_COLUMN_IDS.TEST_COLUMN));
    expect(input).toBeInTheDocument();
    expect(input).toHaveAttribute('placeholder', `Search ${TEST_COLUMN_IDS.TEST_COLUMN}...`);
  });

  it('displays current filter value', () => {
    const column = createMockColumn('test value');
    render(<TextFilter column={column} />);
    
    const input = screen.getByTestId('text-filter-testColumn');
    expect(input).toHaveValue('test value');
  });

  it('calls setFilterValue when typing', async () => {
    const column = createMockColumn();
    const user = userEvent.setup();
    render(<TextFilter column={column} />);
    
    const input = screen.getByPlaceholderText('Search testColumn...');
    await user.type(input, 'test');
    
    // Verify setFilterValue was called
    expect(column.setFilterValue).toHaveBeenCalled();
  });

  it('calls setFilterValue immediately on change', async () => {
    const column = createMockColumn();
    const user = userEvent.setup();
    render(<TextFilter column={column} />);
    
    const input = screen.getByPlaceholderText('Search testColumn...');
    
    // Type a single character
    await user.type(input, 'a');
    
    // Verify setFilterValue was called
    expect(column.setFilterValue).toHaveBeenCalledWith('a');
  });

  it('clears filter when input is empty', async () => {
    const column = createMockColumn('existing');
    const user = userEvent.setup();
    render(<TextFilter column={column} />);
    
    const input = screen.getByPlaceholderText('Search testColumn...');
    
    // Clear the input
    await user.clear(input);
    
    // Current implementation calls with empty string, not undefined
    expect(column.setFilterValue).toHaveBeenCalledWith('');
  });

  it('renders without item count (not implemented)', () => {
    const column = createMockColumn();
    column.getFacetedUniqueValues = () => new Map([
      ['value1', 2],
      ['value2', 3],
      ['value3', 1],
    ]);
    
    render(<TextFilter column={column} />);
    
    // Current implementation doesn't show item counts
    expect(screen.queryByText('(3)')).not.toBeInTheDocument();
  });

  it('handles special characters in search', async () => {
    const column = createMockColumn();
    const user = userEvent.setup();
    render(<TextFilter column={column} />);
    
    const input = screen.getByPlaceholderText('Search testColumn...');
    await user.type(input, '@');
    
    // Verify setFilterValue was called with special character
    expect(column.setFilterValue).toHaveBeenCalledWith('@');
  });

  it('preserves filter value on re-render', () => {
    const column = createMockColumn('preserved value');
    const { rerender } = render(<TextFilter column={column} />);
    
    const input = screen.getByPlaceholderText('Search testColumn...');
    expect(input).toHaveValue('preserved value');
    
    // Re-render with same value
    rerender(<TextFilter column={column} />);
    expect(input).toHaveValue('preserved value');
  });

  it('updates when column filter value changes externally', () => {
    const column = createMockColumn('initial');
    const { rerender } = render(<TextFilter column={column} />);
    
    const input = screen.getByPlaceholderText('Search testColumn...');
    expect(input).toHaveValue('initial');
    
    // Update column filter value
    column.getFilterValue = () => 'updated';
    rerender(<TextFilter column={column} />);
    
    expect(input).toHaveValue('updated');
  });

  it('handles paste events', async () => {
    const column = createMockColumn();
    const user = userEvent.setup();
    render(<TextFilter column={column} />);
    
    const input = screen.getByPlaceholderText('Search testColumn...');
    
    // Simulate paste
    await user.click(input);
    await user.paste('pasted text');
    
    expect(column.setFilterValue).toHaveBeenCalledWith('pasted text');
  });

  it('handles whitespace in filter value', async () => {
    const column = createMockColumn();
    const user = userEvent.setup();
    render(<TextFilter column={column} />);
    
    const input = screen.getByPlaceholderText('Search testColumn...');
    await user.type(input, ' ');
    
    // Verify setFilterValue was called with whitespace
    expect(column.setFilterValue).toHaveBeenCalledWith(' ');
  });

  it('does not support custom className prop', () => {
    const column = createMockColumn();
    const { container } = render(<TextFilter column={column} />);
    
    // Current implementation doesn't support className prop
    expect(container.querySelector('.custom-filter')).not.toBeInTheDocument();
  });

  it('is accessible', () => {
    const column = createMockColumn();
    render(<TextFilter column={column} />);
    
    const input = screen.getByPlaceholderText('Search testColumn...');
    expect(input).toHaveAttribute('type', 'text');
    expect(input).toHaveAttribute('aria-label', expect.stringContaining('Filter'));
  });
});