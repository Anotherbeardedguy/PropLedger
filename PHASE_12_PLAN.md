# Phase 12: Financial Enhancements & Document Viewer

## Overview
Enhance loan management with multi-property support, integrate loan payments into cashflow calculations, add comprehensive financial reporting, and implement in-app document viewing.

## Requirements

### 1. Loan Multi-Property Support
- **Current**: Loan linked to single property
- **New**: Loan can be linked to multiple properties
- **Implementation**:
  - Add `LoanPropertyLinks` junction table
  - Update Loan model to support property list
  - Modify loan creation/edit UI for multi-select
  - Show linked properties in loan details

### 2. Cashflow Integration
- **Loan Installments**: Calculate and show monthly loan payments
- **Upkeep Costs**: Already tracked per unit
- **Task Costs**: Include maintenance task costs in cashflow
- **Display**: Update dashboard monthly cashflow card

### 3. Financials Screen
- **Purpose**: Deep financial insights and reports
- **Features**:
  - Profit & Loss statement
  - Cash flow analysis (detailed)
  - Property-wise performance
  - Year-over-year comparisons
  - Export reports (PDF, CSV)
  - Date range filtering
  - Visual charts and graphs

### 4. Document Viewer
- **In-App Viewing**:
  - PDF files (using pdf_viewer package)
  - Images (JPG, PNG, etc.)
- **External Apps**:
  - Other file types (DOC, XLS, etc.)
  - Use open_file or url_launcher
- **Features**:
  - Full-screen viewer
  - Zoom/pan for images
  - Page navigation for PDFs
  - Share/delete options

## Technical Changes

### Database Schema
```dart
// New table for loan-property links
@DataClassName('LoanPropertyLinkEntity')
class LoanPropertyLinks extends Table {
  TextColumn get id => text()();
  TextColumn get loanId => text().references(Loans, #id)();
  TextColumn get propertyId => text().references(Properties, #id)();
  DateTimeColumn get created => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

### Models
- Update `Loan` model with `propertyIds` list
- Add `MonthlyLoanPayment` helper class
- Create `FinancialReport` models
- Add `CashflowItem` model for detailed breakdown

### Services
- `LoanCalculatorService` - Calculate monthly payments
- `CashflowService` - Aggregate all cashflow sources
- `FinancialReportService` - Generate reports
- `DocumentViewerService` - Handle file viewing

### UI Components
- `FinancialsScreen` - New main screen
- `PropertyMultiSelectDialog` - Select multiple properties
- `PdfViewerScreen` - View PDFs in-app
- `ImageViewerScreen` - View images in-app
- `CashflowBreakdownCard` - Detailed cashflow display
- Financial charts (using fl_chart)

## Dependencies to Add
```yaml
pdf_render: ^1.4.0  # PDF viewing
syncfusion_flutter_pdfviewer: ^24.2.9  # Alternative PDF viewer
fl_chart: ^0.66.0  # Charts
open_file: ^3.3.2  # Open external files
csv: ^6.0.0  # CSV export
```

## Implementation Steps
1. ✅ Create Phase 12 plan
2. Add dependencies to pubspec.yaml
3. Create LoanPropertyLinks table and migration
4. Update Loan model for multi-property support
5. Create LoanCalculatorService for payment calculations
6. Create CashflowService to aggregate all sources
7. Update Dashboard cashflow card with loan payments
8. Create FinancialReportService
9. Build FinancialsScreen UI
10. Implement PDF viewer
11. Implement image viewer
12. Update DocumentsScreen to use new viewers
13. Test all features
14. Update navigation to include Financials tab

## Success Criteria
- [ ] Loans can be linked to multiple properties
- [ ] Monthly loan payments calculated correctly
- [ ] Dashboard shows complete cashflow (rent, upkeep, tasks, loans)
- [ ] Financials screen provides comprehensive insights
- [ ] PDFs viewable in-app
- [ ] Images viewable in-app
- [ ] Other documents open in external apps
- [ ] All tests pass
- [ ] No analyzer errors
