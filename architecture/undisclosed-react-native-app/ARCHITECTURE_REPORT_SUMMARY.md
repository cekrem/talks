---
theme: default
paginate: false
style: |
  section {
    overflow: auto;
    font-size: 0.9rem;
  }

  section::before {
    display: none;
  }
---

# Architecture Report - Executive Summary

**Date:** 2025-11-19  
**Status:** Ready for Team Review

---

## 📋 What's in This Report

We analyzed your Clean Architecture implementation and created a comprehensive guide for improving it. Here are the documents:

### 1. **[Architecture Analysis Report](./ARCHITECTURE_ANALYSIS_REPORT.md)** (Main Document)

- 📄 **50+ pages** of detailed analysis
- Current state assessment
- Problems identified
- Complete migration plan
- Code examples

### 2. **[Quick Reference Guide](./ARCHITECTURE_QUICK_REFERENCE.md)** (Daily Use)

- 📖 **Quick decision trees**
- "Where does this code go?"
- Common patterns
- Anti-patterns to avoid

### 3. **[Migration Example](./MIGRATION_EXAMPLE.md)** (Step-by-Step)

- 🔨 **Concrete refactoring example**
- Before/after code
- Step-by-step instructions
- Apply to all 24 use cases

### 4. **[Thunk Layer Discussion](./THUNK_LAYER_DISCUSSION.md)** (Addresses Concerns)

- 💬 **"Won't thunks make Presentation too large?"**
- Should we add helpers?
- Should we add another layer?
- Pragmatic recommendations

### 5. **[Container Location Rationale](./CONTAINER_LOCATION_RATIONALE.md)** (Design Decision)

- 🏗️ **Why DI container lives outside layers**
- Bootstrap vs business logic
- Where legacy code goes (`src/old/`)

### 6. **[Abstraction Strategy](./ABSTRACTION_STRATEGY.md)** (What to Abstract)

- 🎯 **Beyond repositories, what should be abstracted?**
- Decision framework with checklist
- Analytics, Time Provider, Feature Flags
- Anti-patterns to avoid

---

## 🎯 Key Findings (TL;DR)

### ✅ What's Working Well

1. **4-layer architecture is appropriate** for your complexity level
2. **Domain layer is excellent** - pure, no framework dependencies
3. **Repository pattern works well** - abstracts Firebase/Sanity
4. **DI provides value** for repositories and use cases
5. **Clear separation** between layers (mostly)

### ⚠️ Critical Issues Found

1. **24 use cases coupled to Redux Toolkit** (`createAsyncThunk`)

   - Cannot test without Redux
   - Cannot reuse in scripts/workers
   - Violates framework-agnostic principle

2. **StateManager in wrong layer** (`application/` → should be `presentation/`)

   - Redux is a delivery mechanism, not application logic

3. **3 dependency violations** (Application imports Presentation)
   - `MetricWithValue` type in wrong location
   - Hormone generators in screens folder

---

## 🔧 Recommended Solution

### Decision: **Keep 4 Layers + Decouple Use Cases**

**Why 4 layers:**

- ✅ Right complexity for 24 use cases
- ✅ Team already familiar
- ✅ Industry standard
- ✅ Clear boundaries

**What changes:**

1. Move thunks from use cases → presentation layer
2. Move StateManager → presentation layer
3. Fix type import violations
4. Use cases return `Promise<T>`, not `createAsyncThunk`

---

## 📐 New Architecture Pattern

### Before (Problematic)

```typescript
// ❌ Application layer
@injectable()
export class GetDataUseCase {
  execute = createAsyncThunk(/* Redux stuff */);
}
```

### After (Clean)

```typescript
// ✅ Application layer - pure business logic
@injectable()
export class GetDataUseCase {
  async execute(params: Params): Promise<Result> {
    return await this.repository.getData(params);
  }
}

// ✅ Presentation layer - Redux integration
export const fetchData = createAsyncThunk("data/fetch", async (params) => {
  const useCase = container.resolve(GetDataUseCase);
  return await useCase.execute(params);
});
```

---

## 📊 Migration Scope

### Affected Files

| Category               | Count | Effort          |
| ---------------------- | ----- | --------------- |
| Use cases to refactor  | 24    | 15-20 min each  |
| Thunk files to create  | ~6    | 1-2 hours total |
| Redux slices to update | 13    | 15 min each     |
| ViewModels to update   | ~20   | 5 min each      |
| Test files to update   | ~24   | 20 min each     |

**Total Estimated Time: 27-36 hours** (4-5 days)

### Affected Use Cases (All 24)

**LifeContext (7):**

- GetLifeContextUseCase
- InitiateMenstruationLifeContextUseCase
- RestartMenstruationLifeContextUseCase
- CalculateMenstrualCyclesUseCase
- UpdateMenstrualPhaseLengthsDataUseCase
- RecomputeAfterLifeContextChangeUseCase
- GetStatusModeUseCase

**MetricLog (4):**

- SaveMetricLogsUseCase
- ListMetricLogsUseCase
- ListMetricCategoriesUseCase
- ListBleedingLogsUseCase

**MyHealth (5):**

- SetSicknessAndAilmentsUseCase
- SetSexualActivityUseCase
- SetPhysicalActivityUseCase
- SetDrugUseUseCase
- SetBirthControlUseCase

**Other (8):**

- SetActivityFrequencyUseCase
- ShouldShowCycleTrackingPromptUseCase
- ClosePostPartumsUseCase
- SaveMenstruationOnboardingDataUseCase
- GetInsightUseCase
- GetCarefeedItemsUseCase
- GetCarefeedFiltersUseCase
- SetUserInterestsUseCase

---

## 📅 Suggested Timeline

### Phase 1: Quick Wins (Week 1 - 1 day)

- ✅ Fix type import violations (30 min)
- ✅ Move StateManager to Presentation (3 hours)
- ✅ Move DI container to `src/container.ts` (15 min)
- ✅ Move legacy code to `src/old/` (30 min)
- **Deliverable:** Cleaner layer structure

### Phase 2: Decouple Use Cases (Weeks 2-3 - 3-4 days)

- ✅ Create thunk files (6-8 hours)
- ✅ Refactor all 24 use cases (8-12 hours)
- ✅ Update Redux slices (3-4 hours)
- ✅ Update ViewModels (2-3 hours)
- **Deliverable:** Framework-agnostic use cases

### Phase 3: Optimization (Week 4 - 1 day)

- ✅ Simplify stateless services (2 hours)
- ✅ Fix infrastructure violations (1 hour)
- ✅ Add architecture tests (2 hours)
- **Deliverable:** Enforced boundaries

---

## 🎁 Benefits

### Immediate

✅ **Testability:** Use cases test without Redux  
✅ **Clarity:** Clear separation of concerns  
✅ **Standards:** Follows Clean Architecture principles

### Long-term

✅ **Flexibility:** Could swap Redux for Zustand/MobX  
✅ **Reusability:** Use cases in scripts, workers, CLI  
✅ **Maintainability:** Easier onboarding, clearer patterns  
✅ **Quality:** Enforced boundaries prevent violations

---

## 🚀 Next Steps

### 1. Team Review (This Week)

- [ ] Read executive summary (this document)
- [ ] Review [main report](./ARCHITECTURE_ANALYSIS_REPORT.md) sections 1-6
- [ ] Review [migration example](./MIGRATION_EXAMPLE.md)
- [ ] Discuss and approve plan

### 2. Plan Sprint (Next Week)

- [ ] Create tracking issues (24 use cases + setup tasks)
- [ ] Assign work (pair programming recommended)
- [ ] Set up branch: `architecture/decouple-use-cases`

### 3. Execute Migration (Weeks 2-4)

- [ ] Phase 1: Quick wins
- [ ] Phase 2: Refactor use cases (can be parallelized)
- [ ] Phase 3: Optimization

### 4. Document (Ongoing)

- [ ] Update team wiki with new patterns
- [ ] Add [quick reference](./ARCHITECTURE_QUICK_REFERENCE.md) to onboarding
- [ ] Code review checklist

---

## 📚 How to Use These Documents

### For Team Leads

👉 Read: **[Architecture Analysis Report](./ARCHITECTURE_ANALYSIS_REPORT.md)** (full details)

### For Developers (Daily)

👉 Use: **[Quick Reference Guide](./ARCHITECTURE_QUICK_REFERENCE.md)** (where to put code)

### For Refactoring

👉 Follow: **[Migration Example](./MIGRATION_EXAMPLE.md)** (step-by-step guide)

### For Addressing Concerns

👉 See: **[Thunk Layer Discussion](./THUNK_LAYER_DISCUSSION.md)** (helper/layer concerns)  
👉 See: **[Container Location Rationale](./CONTAINER_LOCATION_RATIONALE.md)** (why outside layers)

### For Architecture Decisions

👉 See: **[Abstraction Strategy](./ABSTRACTION_STRATEGY.md)** (what should be abstracted)

---

## ❓ FAQ

### Q: Do we have to do this?

**A:** No, but highly recommended. Current pattern violates Clean Architecture principles and makes testing/reusability difficult.

### Q: Can we do this incrementally?

**A:** Yes! Start with Phase 1 (quick wins), then tackle use cases one at a time.

### Q: Will this break anything?

**A:** No. This is a refactoring - behavior stays the same, structure improves.

### Q: How long will this take?

**A:** 27-36 hours total (~4-5 days of focused work). Can be parallelized across team.

### Q: What's the ROI?

**A:** Better testability, maintainability, and flexibility. Easier to onboard new developers.

### Q: Can we simplify to 3 layers instead?

**A:** Not recommended. You have 24 use cases - the Application layer provides clear value.

---

## 📞 Questions or Clarifications?

- **Architecture concerns:** Review Section 6 of [main report](./ARCHITECTURE_ANALYSIS_REPORT.md)
- **Migration steps:** See [Migration Example](./MIGRATION_EXAMPLE.md)
- **Daily decisions:** Use [Quick Reference](./ARCHITECTURE_QUICK_REFERENCE.md)
- **"Too large" concerns:** Read [Thunk Layer Discussion](./THUNK_LAYER_DISCUSSION.md)
- **Container location:** Read [Container Location Rationale](./CONTAINER_LOCATION_RATIONALE.md)
- **What to abstract:** Read [Abstraction Strategy](./ABSTRACTION_STRATEGY.md)
- **Technical details:** See [Main Report](./ARCHITECTURE_ANALYSIS_REPORT.md)

---

## ✅ Approval Checklist

Before starting migration:

- [ ] Team has reviewed all documents
- [ ] Migration plan is approved
- [ ] Timeline is agreed upon
- [ ] Tracking issues created
- [ ] Branch created
- [ ] Pair programming partners assigned

---

**Report Status:** ✅ Complete and ready for review  
**Recommended Action:** Schedule team review meeting  
**Priority:** High (architectural debt)  
**Risk:** Low (pure refactoring, no behavior changes)

---

## 📂 Complete Document Set

1. **[Architecture Report Summary](./ARCHITECTURE_REPORT_SUMMARY.md)** ← You are here
2. **[Architecture Analysis Report](./ARCHITECTURE_ANALYSIS_REPORT.md)** (50+ pages, detailed)
3. **[Architecture Quick Reference](./ARCHITECTURE_QUICK_REFERENCE.md)** (daily use)
4. **[Migration Example](./MIGRATION_EXAMPLE.md)** (step-by-step guide)
5. **[Thunk Layer Discussion](./THUNK_LAYER_DISCUSSION.md)** (addresses size concerns)
6. **[Container Location Rationale](./CONTAINER_LOCATION_RATIONALE.md)** (bootstrap design)
7. **[Abstraction Strategy](./ABSTRACTION_STRATEGY.md)** (what to abstract)

---

_Generated: 2025-11-19_  
_Documents created: 7 comprehensive guides_
