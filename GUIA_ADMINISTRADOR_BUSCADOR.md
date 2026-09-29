# Dynamic Search — Administrator Guide

## What is Dynamic Search?

Dynamic Search is a configurable search and filtering component for Salesforce. It lets end users filter records from any object using criteria the admin defines, view the results in a table, and send selected records to the Field Service Dispatcher.

This guide covers everything an administrator needs to know: how the component is placed, how to create and maintain configurations, and how each option affects what the user sees.

---

## Architecture overview

The solution has two components:

| Component | Purpose |
|-----------|---------|
| **Filter Configuration Builder** | Admin tool for creating and managing configurations. Accessed from the **Filter Configuration Builder** custom tab. |
| **Dynamic Search** (LWC) | End-user component placed on Lightning pages, the Scheduling Console, or embedded in a Visualforce page via the Aura container. |

A **configuration** is a saved set of settings that tells the search component which object to query, which fields to show as filters, and what bulk actions to offer. One org can have as many configurations as needed (one per use case). The user selects which configuration to use at runtime — unless the admin pre-selects it.

### Dispatcher Pin system

When a dispatcher clicks **Send to Dispatcher**, the component tags each selected Service Appointment with that dispatcher's identity by writing to the `Dispatcher_Pinned_Ids__c` field (Text 255). Rather than storing full 18-character user IDs — which would exhaust the 255-character limit quickly and cause false positives in list view `contains` filters — the field stores short numeric pin values in the format `;N;` (e.g. `;42;`).

The mapping between users and their pin values is stored in the **Dispatcher Pin** Custom Metadata Type (`Dispatcher_Pin__mdt`). An administrator must populate this type with one record per dispatcher before the Send to Dispatcher feature works for that user.

---

## Step 1 — Placing the component

### Option A: Lightning App Builder (record page, app page, home page)

1. Open **App Builder** for the target page.
2. Drag **Dynamic Search** from the component list onto the canvas.
3. In the component properties panel, optionally fill in **Configuration Name** — the API Name (`Name` field) of a `Filter_Configuration__c` record.
   - If left blank, a picklist appears to let the user choose the configuration at runtime.
   - If filled in, the picklist is hidden and the named configuration loads automatically.
4. Save and activate the page.

### Option B: Scheduling Console (Field Service) — Mass Action

The Scheduling Console uses the Visualforce page `DynamicFilterSearch`, which embeds the component via an Aura container. The Aura container reads the active configuration from a **Custom Metadata record** (see Step 2 below).

To add it as a Mass Action:

1. Open **Field Service Admin** → **Dispatcher Console UI** → **Custom Actions**.
2. Click **New Action**, set type to **Visualforce**, and select the page `DynamicFilterSearch`.
3. Set the **Custom Permission** to `DynamicSearch`.
4. Save.

The component will appear in the Mass Actions panel of the Scheduling Console for users who have the `Dynamic_Filter_User` permission set (which grants the `DynamicSearch` custom permission).

### Option D: Service Console — Utility Bar

The component can be placed in the utility bar of any Lightning console app (e.g. the Service Console). Each entry in the utility bar is an independent instance, so you can add it once per object, each pre-loaded with its own configuration.

1. Go to **Setup** → **App Manager**.
2. Find the target console app (e.g. **Service Console**) and click **Edit**.
3. In the left navigation, click **Utility Items (App Option)**.
4. Click **Add Utility Item** and search for **Dynamic Search**.
5. Configure the item:
   - **Label**: a user-facing name for this panel (e.g. `Search Appointments`, `Search Territories`).
   - **Icon**: an SLDS utility icon name (e.g. `utility:search`, `utility:filterList`).
   - **Panel Width / Height**: adjust to the desired size (recommended: 400 × 500 or larger).
   - **Configuration Name**: the exact `Name` field value of the `Filter_Configuration__c` record you want to pre-load (e.g. `ServiceAppointment`). Leaving it blank lets the user choose a configuration at runtime.
6. Click **Save**.
7. Repeat steps 4–6 for each additional object (e.g. `ServiceTerritory`, `User`, `ServiceResource`), creating one utility bar item per object.

> When `Configuration Name` is filled in, the configuration selector is hidden from the user and the component loads that configuration automatically on open.

---

### Option C: Scheduling Console — Default configuration via Custom Metadata

When the component loads from the Visualforce/Aura path, it reads the configuration name from a **Custom Metadata Type** record:

1. Go to **Setup** → **Custom Metadata Types** → **Dynamic Filter Setting** → **Manage Records**.
2. Edit the existing record (or create a new one).
3. Fill in **Configuration Name** with the exact `Name` (Label field, not the API name) of the `Filter_Configuration__c` record you want to use.
4. Save.

The Aura container will then pass that configuration name to the LWC automatically, hiding the configuration selector from end users.

---

## Step 2 — Prerequisite: Field Set on the target object

The configuration builder only shows fields that belong to a **Field Set named `DynamicSearch`** on the target object. If that field set does not exist, the "Object and Fields" section of the builder will show an info message and no fields will be available.

**Before creating a configuration for an object, create the field set:**

1. Go to **Setup** → **Object Manager** → select the target object (e.g. ServiceAppointment) → **Field Sets**.
2. Click **New**.
3. Set the **Field Set Name** to `DynamicSearch` (this is the API name — it must match exactly).
4. Add the fields you want to be available as search filters.
5. Save.

> Only fields in this field set will appear in the configurator. This is intentional: it prevents admins from accidentally exposing sensitive fields and keeps the field list manageable.

---

## Step 3 — Creating a configuration

Open the **Filter Configuration Builder** tab. Click **New Configuration**.

The form is divided into four sections, each described in detail below.

---

### Section 1: Basic Information

| Field | Required | Description |
|-------|----------|-------------|
| **Configuration Name** | Yes | The API `Name` of the record. Used when pre-setting the config via App Builder or the Custom Metadata record. Use a short descriptive value without spaces (e.g. `ServiceAppointments_Active`). |
| **Label** | Yes | The display label shown in the configuration picklist when the user is allowed to choose. Make it user-friendly (e.g. `Active Service Appointments`). |
| **Grid Columns** | Yes | How many filter fields appear per row (1–4). The recommended value is 3 for most screen sizes. Use 2 for fields with long labels, 4 for short ones like Status. |
| **Active** | — | When unchecked, the configuration does not appear in the user-facing picklist. Use this to prepare a configuration before making it available, or to retire one without deleting it. |

---

### Section 2: Object and Fields

#### 2a. Select Object

Choose the Salesforce object the search will query. The list shows all accessible, queryable objects in the org.

> Changing the object after fields have been added resets the configured fields and the prefilter. Make sure you choose the correct object before adding fields.

#### 2b. Select Fields (dual-listbox)

After choosing an object, a dual-listbox appears. The **Available** side lists all fields in the object's `DynamicSearch` field set. Move the ones you want as search filters to the **Selected** side, then click **Add Fields**.

Each added field appears as a card in Section 3 (Configure Filter Fields). You can add fields in multiple batches — run through the process again to add more.

The field type is detected automatically from the field's Salesforce type and maps as follows:

| Salesforce type | Filter widget shown to user |
|-----------------|----------------------------|
| Text, Email, Phone, URL | Text input with wildcard support |
| Picklist, Multipicklist | Multiselect inline panel |
| Date | Inline date range picker |
| DateTime | Inline date/time range picker (times matched in the running user's timezone) |
| Number, Currency, Percent, Integer | Number input (exact match) |
| Checkbox / Boolean | Checkbox |
| Lookup / Reference / Master-Detail | Inline lookup search panel (magnifier icon, multi-select tags) |

---

### Section 3: Configure Filter Fields

Once fields have been added, each appears as a draggable card. This section lets you:

#### Reorder fields

Drag a card to a new position. The number shown on each card (`#1`, `#2`, etc.) reflects the display order in the filter panel. This also determines the column layout together with the **Grid Columns** setting.

> Example: with Grid Columns = 3 and five fields, the first row shows fields 1–3 and the second row shows fields 4–5.

#### Remove a field

Click the trash icon on a card to remove it from the configuration. This does not affect the Field Set on the object.

#### Multi-search (text fields only)

Check the **Multi Search** checkbox on a text field card to allow the user to search for multiple values at once using a separator character.

- **Separator Character**: the character the user types between values (default is a space). The search returns records matching **any** of the provided values (OR logic).
- Example: with separator ` ` (space), the user types `SA-001 SA-002` and gets records where the field is exactly `SA-001` OR exactly `SA-002` — or using wildcards: `*001* *002*` gets records containing "001" OR "002".

> Multi-search is only meaningful for text-type fields. Picklist, date, and number fields have their own multi-value support built in.

---

### Section 4: Prefilter (Optional)

The prefilter applies an invisible, permanent restriction to every search run with this configuration. The end user does not see it; it is always active in addition to whatever filters they type.

Use case: you want to show only ServiceAppointments with Status "Scheduled" or "In Progress" — the user should never see Cancelled or Completed ones regardless of what they search for.

#### How to configure it

1. Check **Enable Prefilter**.
2. In **Prefilter Field**, choose a picklist field from the object. Only fields of type `Picklist` (not Multipicklist) are listed here.
3. In **Prefilter Values** (dual-listbox), move the allowed values to the **Selected** side. The search will only return records whose picklist field value is in this list.

> Leave the prefilter disabled (default) if you want all records to be reachable by the user's own filters.

**Example SOQL generated** for the case above:
```sql
SELECT ... FROM ServiceAppointment
WHERE AppointmentNumber LIKE '%009%'
AND Status IN ('Scheduled', 'In Progress')
WITH USER_MODE LIMIT 2000
```

The `AND Status IN (...)` part is the prefilter; the user never typed it.

---

### Section 5: Bulk Actions

Bulk actions appear as buttons above the results table. When the user selects records and clicks one, the action executes against all selected records.

#### Adding a bulk action

Click **Add Bulk Action**. A new form row appears with these fields:

| Field | Required | Description |
|-------|----------|-------------|
| **Action Label** | Yes | Button text shown to the user (e.g. `Assign to Territory`). |
| **Action Type** | Yes | `Apex` or `Flow`. |
| **Apex Class** | If Apex | Dropdown of active Apex classes in the org. The class must implement the `BulkActionHandler` interface. |
| **Flow API Name** | If Flow | Dropdown of active Autolaunched Flows. The flow receives the selected record IDs. |
| **Icon Name** | — | SLDS utility icon (e.g. `utility:check`, `utility:assign`). Defaults to `utility:check`. Browse icons at the SLDS icon library. |
| **Order** | Yes | Display order among bulk action buttons (lower number = left). |

#### Removing a bulk action

Click the trash icon on the action row.

> The **Send to Dispatcher** button is always available and is not configured here — it is built into the component.

---

### Section 6: Saving the configuration

Click **Save** at the top right of the form. The system validates:

- Configuration Name and Label are filled in.
- An object is selected.
- At least one filter field has been added.

On success, the configuration is saved and you are returned to the list. The configuration is now available immediately to end users (if Active is checked).

---

## Editing an existing configuration

From the configuration list, click the action menu (⋮) on any row and choose **Edit**. All sections are pre-populated with the saved values. Make your changes and click **Save**.

> Saving a configuration deletes and re-creates the associated `Filter_Field__c`, `Display_Column__c`, and `Bulk_Action__c` records in a single transaction with rollback on failure. There is no partial save.

---

## Deleting a configuration

From the list, click ⋮ → **Delete**. A confirmation prompt appears. Deletion cascades to all related `Filter_Field__c`, `Display_Column__c`, and `Bulk_Action__c` records.

> A deleted configuration cannot be recovered. If you want to hide it from users temporarily, uncheck **Active** instead.

---

## Managing Dispatcher Pin records

Before a dispatcher can use **Send to Dispatcher**, they must have a record in the `Dispatcher_Pin__mdt` Custom Metadata Type. The type has three fields:

| Field | Description |
|-------|-------------|
| **Label / Record Name** | A human-readable name for the record (e.g. the dispatcher's full name). |
| **Username** (`Username__c`) | The dispatcher's Salesforce username (e.g. `jdoe@company.org`). |
| **User ID** (`User_Id__c`) | The dispatcher's 18-character Salesforce User ID. Used at runtime to look up the pin value. |
| **Pin Value** (`Pin_Value__c`) | A unique integer assigned to this dispatcher. Must be unique across all records. |

**To add records:**

1. Go to **Setup** → **Custom Metadata Types** → **Dispatcher Pin** → **Manage Records**.
2. Click **New** and fill in all four fields.
3. Save.

**Pin value assignment rules:**

- Each dispatcher must have a distinct integer (e.g. 1, 2, 3 … up to ~600).
- The value is stored as `;N;` in `Dispatcher_Pinned_Ids__c`, so searching for `;10;` in a list view never matches `;100;` or `;108;`.
- Do not reuse a pin value if a dispatcher leaves — retire their record instead by deleting it, and keep the integer reserved to avoid matching old data that has not yet been cleared.

> If a dispatcher has no `Dispatcher_Pin__mdt` record, clicking **Send to Dispatcher** will silently do nothing for that user. Check this type first when a dispatcher reports that the button has no effect.

---

## Permissions

End users need the **Dynamic Filter User** permission set assigned. It grants:

- Read/Edit on `Filter_Configuration__c`, `Filter_Field__c`, `Display_Column__c`, `Bulk_Action__c`.
- Read on `ServiceAppointment.Dispatcher_Pinned_Ids__c`.
- The `DynamicSearch` custom permission (required for the Mass Action to appear in the Scheduling Console).

Admins who manage configurations also need:

- Access to the **Filter Configuration Builder** custom tab.
- Create/Delete permissions on the above objects (granted via the same PS or a separate admin profile).
- Customize Application permission (or System Administrator profile) to manage `Dispatcher_Pin__mdt` records.

---

## Considerations and limits

| Topic | Detail |
|-------|--------|
| **Result limit** | Each search returns a maximum of 2,000 records. If users consistently hit this limit, add more specific default filters or refine the Field Set to narrower fields. |
| **Field types excluded from text search** | Dates, datetimes, picklists, numbers, checkboxes, and lookups use dedicated widgets. Lookup/Reference/Master-Detail fields use an inline search panel that resolves the related object at runtime (via `getReferenceTo()`) and filters by the selected record IDs. |
| **Wildcard behavior** | Text fields require explicit wildcards (`*`, `+`). Without them, the search is an exact match. Picklist, date, lookup, and number fields do not support wildcards. |
| **DateTime timezone** | DateTime filters are evaluated in the running user's timezone: the time the user picks is offset to their local timezone before matching against the UTC value stored in the database. Two users in different timezones searching the same time see results relative to their own clock. |
| **Lookup search** | The lookup panel returns up to 20 matches per search term and allows multiple selections (combined with OR). The related object is detected automatically from the field — no extra configuration is required. |
| **Prefilter and user filters** | Prefilter values are combined with user-entered values using AND. They are never overridable by the user. |
| **WITH USER_MODE** | All queries run in user mode. Users only see records they have read access to, regardless of how the configuration is set up. |
| **Field Set dependency** | If the `DynamicSearch` field set is removed from an object, existing configurations for that object will fail to load fields in the builder. They continue to work for end users (filter fields are stored in `Filter_Field__c`, not derived from the field set at runtime). |
| **Configurations are not org-aware** | Configurations are stored as data records (`Filter_Configuration__c`), not metadata. They are not included in deployments unless explicitly extracted and loaded. |

---

## Quick reference: field mapping between sections

When you save a configuration, the component stores the following records:

| Saved as | Stores |
|----------|--------|
| `Filter_Configuration__c` | Name, Label, Object API Name, Grid Columns, Active, Prefilter settings |
| `Filter_Field__c` (one per filter field) | Field API Name, Label, Type, Order, Multi-search settings |
| `Display_Column__c` (one per filter field) | Same fields as above, used to build the results table columns |
| `Bulk_Action__c` (one per bulk action) | Label, Type (Apex/Flow), Class or Flow name, Icon, Order |

The Display Columns are auto-generated from the filter fields with a default width of 150px. Column widths cannot be customised from the builder currently.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| No fields shown in "Select Fields" | The object has no `DynamicSearch` field set, or the field set is empty | Create the field set on the object with the desired fields |
| Configuration not visible in the user-facing picklist | Active is unchecked | Edit the configuration and check Active |
| User sees all configurations (expected to see only one) | `configurationName` not set in App Builder, or Custom Metadata record not filled in | Set the property in App Builder or fill in the Custom Metadata record |
| Search returns no results | Prefilter is too restrictive, or user typed an exact value without wildcards | Check the prefilter values; remind users to use `*...*` for partial matches |
| Bulk action button does not appear | Configuration saved before bulk action was added, or the action type/class is missing | Edit the configuration and verify the bulk action is complete |
| Mass Action not visible in Scheduling Console | User lacks `DynamicSearch` custom permission, or VF page not accessible | Assign `Dynamic_Filter_User` permission set; verify VF page security |
| Dynamic Search utility bar item not visible | Item not added to the app's Utility Items, or user's profile lacks access to the app | Go to Setup → App Manager → Edit the console app → Utility Items, and verify the item exists; also check app assignment in the app's User Profiles tab |
| Utility bar item opens but loads wrong object | `Configuration Name` property not filled in, or the value does not match any active `Filter_Configuration__c` record name | Edit the utility item in App Manager and set `Configuration Name` to the exact `Name` field of the intended configuration |
| Send to Dispatcher has no effect for a specific user | The user has no record in `Dispatcher_Pin__mdt` | Add their record under **Setup → Custom Metadata Types → Dispatcher Pin → Manage Records** |
| Two dispatchers share pin results in the list view | Duplicate `Pin_Value__c` on two `Dispatcher_Pin__mdt` records | Each dispatcher must have a unique pin value; fix the duplicate record |
