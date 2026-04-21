# Domain Model: Invoicing

## InvoiceModel
**File:** `lib/models/invoice_model.dart`

### Fields
| Field | Type | Default | Notes |
|---|---|---|---|
| `id` | `String` | required | Firestore document ID |
| `invoiceNumber` | `String` | required | Human-readable e.g. INV-001 |
| `clientName` | `String` | required | Denormalized from Customer |
| `customerPhone` | `String?` | null | Denormalized from Customer |
| `customerId` | `String?` | null | FK → customers/{customerId} |
| `date` | `DateTime` | required | Invoice date |
| `revenue` | `double` | required | **Legacy** — written at creation, not updated |
| `status` | `String` | required | `'draft'` \| `'posted'` \| `'cancelled'` |
| `items` | `List<InvoiceItem>` | required | Inline array, stored in Firestore document |
| `notes` | `String?` | null | Free-text |
| `createdAt` | `DateTime` | required | |
| `updatedAt` | `DateTime` | required | Updated on every write |
| `invoiceType` | `String` | `'sales'` | `'sales'` \| `'purchase'` |
| `amountPaid` | `double` | `0.0` | Cumulative — grows with each payment |
| `paymentMethod` | `String` | `'Cash'` | `'Cash'` \| `'Online'` \| `'Cheque'` |
| `followUpDate` | `DateTime?` | null | For payment reminder scheduling |
| `isDeleted` | `bool` | `false` | Soft-delete for drafts only |
| `cancelledAt` | `DateTime?` | null | Set when status → cancelled |
| `cancelReason` | `String?` | null | Required on cancellation |
| `modifiedFlag` | `bool` | `false` | `true` when a return has been applied |
| `modifiedReason` | `String?` | null | Reason for return modification |
| `modifiedAt` | `DateTime?` | null | When modification occurred |
| `refundAdjustment` | `double` | `0.0` | Pending return credit applied to this invoice |

### Computed Getters
| Getter | Formula | Notes |
|---|---|---|
| `subtotal` | `sum(item.price * item.quantity)` | |
| `taxRate` | `0.0` | Hardcoded — no tax system implemented |
| `taxAmount` | `subtotal * taxRate / 100` | Always 0 currently |
| `total` | `subtotal + taxAmount` | Same as subtotal while taxRate = 0 |
| `adjustedTotal` | `total - refundAdjustment` | **True payable amount** |
| `effectiveRevenue` | `adjustedTotal` | Use this for analytics, not `revenue` |
| `remainingAmount` | `adjustedTotal - amountPaid` | Negative = overpaid |
| `absoluteRemainingAmount` | `(adjustedTotal - amountPaid).abs()` | Always positive |
| `isOverpaid` | `amountPaid > adjustedTotal` | |
| `isFullyPaid` | `(adjustedTotal - amountPaid).abs() < 0.01` | Epsilon comparison |
| `paymentStatus` | enum `PaymentStatus` | `paidInFull` \| `balanceDue` \| `refundDue` |

### Enums

**InvoiceStatus** (string values stored in Firestore):
- `draft` — created but not committed
- `posted` — committed, stock deducted
- `cancelled` — terminal state, stock reversed

**PaymentStatus** (computed, not stored):
- `paidInFull` — `|adjustedTotal - amountPaid| < 0.01`
- `balanceDue` — `amountPaid < adjustedTotal`
- `refundDue` — `amountPaid > adjustedTotal`

---

## InvoiceItem
**Location:** Inline class in `lib/models/invoice_model.dart`; stored as array inside invoice document

| Field | Type | Notes |
|---|---|---|
| `name` | `String` | Item name — used for inventory fuzzy matching on returns |
| `quantity` | `int` | Must be positive |
| `price` | `double` | Per-unit price |
| `totalPrice` | `double` (computed) | `quantity * price` |

---

## Firestore Path
```
users/{uid}/invoices/{invoiceId}
  items: [...] // inline array, no sub-collection
```
