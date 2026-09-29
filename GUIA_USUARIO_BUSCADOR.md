# Dynamic Search — User Guide

## What is it?

The Dynamic Search component lets you filter and find records using configurable criteria, review the results in a table, and send selected records to the Field Service Dispatcher in one click.

---

## Interface overview

Depending on how the component is placed, you will see one of two layouts:

- **Embedded mode** (inside the Scheduling Console): the filter panel is always visible, no expand/collapse button.
- **Standalone mode** (on a Lightning page): the panel is hidden behind an **Advanced Search** button. Click it to expand or collapse the filters.

---

## Step 1 — Select a configuration (standalone only)

If no configuration has been pre-set by your admin, a **Search Configuration** picklist appears at the top. Choose the configuration that matches the object and filters you need. Once selected, the filter fields load automatically.

If the picklist is not shown, the configuration is already fixed and you can go straight to Step 2.

---

## Step 2 — Fill in the filters

Each filter field accepts a different kind of value depending on its type.

### Text fields

Type any value. Use **wildcards** to broaden the search:

| Pattern | Meaning | Example |
|---------|---------|---------|
| `SA-001` | Exact match | Finds only `SA-001` |
| `*001*` | Contains "001" | Finds `SA-001`, `X-0010`, `TMP-0011` |
| `SA-*` | Starts with "SA-" | Finds `SA-001`, `SA-123` |
| `*001` | Ends with "001" | Finds `SA-001`, `X-001` |
| `*00+` | Ends with "00" + one character | Finds `SA-001`, `X-009` |

> `*` matches any number of characters. `+` matches exactly one character. Without wildcards the search is an exact match.

### Multi-search text fields

Some text fields support searching for several values at once. Type each value separated by the configured separator (usually a space or semicolon). The search returns records that match **any** of the values.

Example: `Scheduled Dispatched` finds records where Status is "Scheduled" **or** "Dispatched".

### Date fields

Click the field to open an inline date range panel:

1. Set **Start date** — the search will return records on or after this date.
2. Set **End date** — the search will return records on or before this date.
3. Click the **check** button to confirm. The field shows `dd/mm/yyyy - dd/mm/yyyy`.
4. To clear the range, click the **clear** (X) button.

You can fill in only one side of the range. For example, set only an End date to find all records up to that day.

### Date/Time fields

Same as date fields, with two extra time selectors — **Start time** and **End time**. If you leave the time fields empty, the search uses 00:00:00 for the start and 23:59:59 for the end of the selected days.

The field displays: `dd/mm/yyyy HH:mm - dd/mm/yyyy HH:mm`.

> **Times are in your own timezone.** The times you pick are matched against the times you see, not the raw values stored in the database. For example, if a record is stored as 10:00 UTC and your timezone shows it as 12:00, then searching for 11:00 compares against the 12:00 you see. You don't need to convert anything — just use the time as it appears to you.

### Lookup fields

Lookup and master-detail fields show a **search (magnifier) icon** on the right. Click it to open an inline panel where you can search and select one or more related records:

1. Type in the search box to find records by name.
2. Click a result to add it — each selection appears as a removable **tag** (click the **X** on a tag to remove it).
3. Repeat to select multiple records.
4. Click the **check** button to confirm. The panel closes and the field shows the selected values separated by `;`.
5. To clear the whole selection, click the **clear** (X) button.

When you have more selections than fit in the field width, the text is truncated with `...` (the field does not grow). Click the magnifier again to reopen the panel and see all selected tags.

The search returns records that match **any** of the selected values (OR logic).

### Picklist fields

Click the field to open an inline list of available values:

1. Click one or more values to select them (a checkmark appears next to each selected value).
2. Click the **check** button to confirm. The field shows the selected values separated by commas.
3. To clear, click the **clear** (X) button.

The search returns records that match **any** of the selected values (OR logic).

### Number fields

Type a numeric value. The search finds records with that exact value.

### Checkbox fields

Check or uncheck the box. The search filters by `true` or `false`.

---

## Step 3 — Run the search

Once you have filled in the filters you need, you have two options:

### Search

Runs the search and displays the results in the table below. No records are selected or sent anywhere — you stay in control.

### Search and send

Runs the search, **automatically selects all results**, and sends them to the Dispatcher. If the component is inside a modal action, the modal closes automatically after sending. Use this when you want to push the full result set to the Dispatcher in one step.

---

## Step 4 — Work with results

After a search the results table appears.

### Result count

A message above the table shows how many records were found (e.g. "12 records found").

### Pagination

If there are more records than the current page size:

- Use **Previous / Next** to navigate pages.
- Change the **Records per page** selector (options: 10, 25, 50, 100) to see more at once.

### Selecting records

Click the checkbox on the left of any row to select it. You can select multiple rows across pages.

### Send selected records to the Dispatcher

Once you have selected the rows you want, click **Send to Dispatcher** (available both above and below the table). Only the currently selected rows are sent.

---

## Step 5 — Buttons reference

| Button | Action |
|--------|--------|
| **Search** | Runs the search with the current filters. |
| **Search and send** | Runs the search, selects all results, and sends them to the Dispatcher. |
| **Clear** | Empties all filter fields and clears the results table. |
| **Clear Dispatcher filter** | Removes the current filter applied to the Dispatcher view (does not clear the search filters). |
| **Send to Dispatcher** | Sends the currently selected rows to the Dispatcher. |

---

## Tips

- **No wildcards = exact match.** If you type `SA-001` in a text field you will only get the record with that exact value. Add `*` around the term (`*SA-001*`) to find it as a substring.
- **Combine filters.** All filled-in fields are applied together as AND conditions. A prefilter may also be active (configured by the admin) — you will not see it, but it further narrows the results.
- **Partial date ranges are valid.** You can set only a start date or only an end date.
- **Date/Time filters use your timezone.** The time you pick is compared against the time as you see it, not the stored UTC value — no manual conversion needed.
- **Lookup selection is multiple.** Use the magnifier icon to search and add several related records as tags. The field truncates the display but keeps every selection.
- **Picklist order does not matter.** Selecting "Scheduled" and "In Progress" returns the same results regardless of the order you click them.
- **The table is read-only.** Clicking a row selects/deselects it; it does not open the record.
- **Maximum results: 2,000.** If your search is too broad, add more filters to narrow it down.
