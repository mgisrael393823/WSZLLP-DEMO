import React, { useEffect, useState } from 'react';
import { Column } from '@tanstack/react-table';
import { Calendar } from 'lucide-react';
import Input from '../Input';
import { cn } from '@/lib/utils';

interface DateRangeFilterProps<TData> {
  column: Column<TData, unknown>;
  className?: string;
}

export function DateRangeFilter<TData>({ column, className }: DateRangeFilterProps<TData>) {
  const columnFilterValue = column.getFilterValue() as [string, string] | undefined;
  const [startDate, setStartDate] = useState(columnFilterValue?.[0] ?? '');
  const [endDate, setEndDate] = useState(columnFilterValue?.[1] ?? '');

  useEffect(() => {
    setStartDate(columnFilterValue?.[0] ?? '');
    setEndDate(columnFilterValue?.[1] ?? '');
  }, [columnFilterValue]);

  const minMaxValues = column.getFacetedMinMaxValues?.() as [string, string] | undefined;
  const minDate = minMaxValues?.[0];
  const maxDate = minMaxValues?.[1];

  const updateFilter = (nextStart: string, nextEnd: string) => {
    if (!nextStart && !nextEnd) {
      column.setFilterValue(undefined);
      return;
    }

    column.setFilterValue([nextStart, nextEnd]);
  };

  const handleStartDateChange = (value: string) => {
    setStartDate(value);
    if (endDate && value > endDate) {
      setEndDate('');
      updateFilter(value, '');
    } else {
      updateFilter(value, endDate);
    }
  };

  const handleEndDateChange = (value: string) => {
    setEndDate(value);
    updateFilter(startDate, value);
  };

  return (
    <div className={cn('flex gap-2', className)} data-testid={`date-range-filter-${column.id}`}>
      <Input
        type="date"
        value={startDate}
        onChange={(e) => handleStartDateChange(e.target.value)}
        leftIcon={<Calendar className="h-4 w-4" />}
        placeholder="yyyy-mm-dd"
        className="mb-0 flex-1"
        size="sm"
        min={minDate}
        max={maxDate}
        data-testid={`date-filter-start-${column.id}`}
        aria-label="Start date"
      />
      <Input
        type="date"
        value={endDate}
        onChange={(e) => handleEndDateChange(e.target.value)}
        leftIcon={<Calendar className="h-4 w-4" />}
        placeholder="yyyy-mm-dd"
        className="mb-0 flex-1"
        size="sm"
        min={startDate || minDate}
        max={maxDate}
        data-testid={`date-filter-end-${column.id}`}
        aria-label="End date"
      />
    </div>
  );
}
