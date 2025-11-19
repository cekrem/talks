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

# Architecture Analysis Report

**Project:** Undisclosed React Native  
**Date:** 2025-11-19  
**Analysis Scope:** Clean Architecture implementation in `/src`

---

## Executive Summary

### Key Findings

✅ **Strengths:**

- Clear 4-layer architecture with proper dependency inversion
- Well-defined domain entities with no framework dependencies
- Repository pattern successfully abstracts Firebase and Sanity
- 24 use cases provide solid application orchestration
- Dependency injection (tsyringe) enables testability

⚠️ **Critical Issues:**

- **24 use cases** are coupled to Redux Toolkit (`createAsyncThunk`)
- **StateManager** is misplaced in Application layer (should be Presentation)
- **3 dependency violations** where Application imports from Presentation
- Use cases are not framework-agnostic (cannot be reused outside Redux)

### Recommendations

1. **Keep 4-layer architecture** - appropriate complexity level for this application
2. **Decouple use cases from Redux** - move thunks to Presentation layer
3. **Relocate StateManager** from `application/` to `presentation/state/`
4. **Fix cross-layer imports** - move shared types to proper locations

**Estimated Impact:** High value, low-to-medium migration effort

---

## Table of Contents

1. [Current Architecture Overview](#1-current-architecture-overview)
2. [Layer-by-Layer Analysis](#2-layer-by-layer-analysis)
3. [Dependency Violations](#3-dependency-violations)
4. [DI Container Usage Analysis](#4-di-container-usage-analysis)
5. [Redux Integration Problem](#5-redux-integration-problem)
6. [Recommended Architecture](#6-recommended-architecture)
7. [Migration Strategy](#7-migration-strategy)
8. [Code Examples](#8-code-examples)
9. [Decision Framework](#9-decision-framework)

---

## 1. Current Architecture Overview

### Layer Statistics

| Layer              | Files (TS/TSX) | Purpose                                        | Dependencies           |
| ------------------ | -------------- | ---------------------------------------------- | ---------------------- |
| **Domain**         | 38             | Entities, Value Objects, Repository Interfaces | None ✅                |
| **Application**    | 109            | Use Cases (24), Services, StateManager, Types  | Domain ✅              |
| **Infrastructure** | 51             | Firebase/Sanity implementations                | Domain, Application ✅ |
| **Presentation**   | 59             | ViewModels (hooks), Components                 | Domain, Application ✅ |

**Note:** DI container (`container.ts`) lives outside the 4-layer structure as a "bootstrap" concern. Legacy code resides in `src/old/`.

### Dependency Flow

```
┌──────────────────────────────────────────┐
│         Presentation Layer               │
│   (ViewModels, Components, Screens)      │
│          59 TS/TSX files                 │
└──────────────┬───────────────────────────┘
               │ depends on
               ↓
┌──────────────────────────────────────────┐
│         Application Layer                │
│  (Use Cases, Services, StateManager)     │
│          109 TS files                    │
└──────────┬───────────────────────────────┘
           │ depends on
           ↓
┌──────────────────────────────────────────┐
│          Domain Layer                    │
│    (Entities, Value Objects)             │
│          38 TS files                     │
└──────────────────────────────────────────┘
           ↑
           │ implements
           │
┌──────────┴───────────────────────────────┐
│        Infrastructure Layer              │
│     (Firebase, Sanity implementations)   │
│          51 TS files                     │
└──────────────────────────────────────────┘

  DI Container (container.ts) - outside layers
  Legacy code (src/old/) - being phased out
```

### Import Analysis

| Import Direction                 | Count | Status           |
| -------------------------------- | ----- | ---------------- |
| Application → Domain             | 147   | ✅ Expected      |
| Presentation → Application       | 41    | ✅ Expected      |
| Infrastructure → Domain          | 10+   | ✅ Expected      |
| **Application → Presentation**   | **3** | ❌ **VIOLATION** |
| **Application → Infrastructure** | **1** | ❌ **VIOLATION** |

---

## 2. Layer-by-Layer Analysis

### 2.1 Domain Layer ✅ EXCELLENT

**Location:** `src/domain/`

**Contents:**

- 38 TypeScript files
- Entities: `LifeContext`, `Pregnancy`, `Menstruation`, `Parent`, `Abortion`
- Value Objects: `Week`, `DateRange`, `MetricLog`
- Repository Interfaces (contracts)

**Quality Assessment:**

✅ **Strengths:**

- Pure TypeScript - no framework dependencies
- Well-defined entity hierarchy
- Uses value objects appropriately
- Repository interfaces define clear contracts

✅ **Example - Clean Entity:**

```typescript
// src/domain/entities/LifeContext/LifeContext.entity.ts
export type LifeContextEntity = {
  id: LifeContextId;
  type: LifeContextType;
  startDate: Date;
  endDate?: Date;
  isActive: boolean;
  metadata?: LifeContextMetadata;
  getMetadata(): LifeContextMetadata;
  setId(id: LifeContextId): void;
};
```

**No changes needed** - this layer is well-architected.

---

### 2.2 Application Layer ⚠️ NEEDS IMPROVEMENT

**Location:** `src/application/`

**Contents:**

- 109 TypeScript files
- **24 Use Cases** (business workflows)
- 8 Application Services
- Types and constants
- **StateManager/** (Redux store, slices, listeners)

**Quality Assessment:**

✅ **Strengths:**

- Clear use case abstraction
- Dependency injection throughout
- Services encapsulate complex logic
- 147 imports from Domain (proper dependency)

❌ **Problems:**

1. **Use Cases Coupled to Redux**

   - All 24 use cases return `createAsyncThunk`
   - Cannot test without Redux
   - Cannot reuse in different contexts (CLI, scripts, etc.)

2. **StateManager Misplaced**

   - Redux is a delivery mechanism (Presentation concern)
   - `StateManager/` should be in `presentation/state/`
   - 13 slice files mixed with application logic

3. **Cross-Layer Violations**
   - Imports `MetricWithValue` from Presentation layer
   - Creates circular dependency risk

---

### 2.3 Infrastructure Layer ✅ GOOD

**Location:** `src/infrastructure/`

**Contents:**

- 51 TypeScript files
- Firebase repository implementations
- Sanity repository implementations
- Serializers and mappers

**Note:** DI container has been moved to `src/container.ts` (outside the 4 layers) as it's a bootstrap/wiring concern that touches all layers.

**Quality Assessment:**

✅ **Strengths:**

- Clean implementation of repository interfaces
- Proper use of dependency injection
- Firebase/Sanity details hidden behind abstractions
- Serializers handle data transformation

✅ **Example - Repository Implementation:**

```typescript
// src/infrastructure/firebase/LifeContext/LifeContextRepositoryImpl.firebase.ts
@injectable()
export class LifeContextRepositoryImplFirebase implements LifeContextRepository {
  async getAll(userId?: string): Promise<LifeContext[]> {
    return firestore()
      .collection('moduleUserData')
      .where('uids', 'array-contains', uid)
      .get()
      .then(querySnapshot => /* ... */);
  }
}
```

⚠️ **Minor Issue:**

- Container imports from `screens/` (presentation concern)
- Should move hormone generators to application/services

---

### 2.4 Presentation Layer ✅ GOOD STRUCTURE

**Location:** `src/presentation/`

**Contents:**

- 59 TypeScript/TSX files
- ViewModels (custom hooks)
- Calendar components
- Metric tracking components
- Shared UI utilities

**Quality Assessment:**

✅ **Strengths:**

- ViewModels properly orchestrate use cases
- Clean separation from UI components
- 41 imports from Application (proper dependency)

✅ **Example - ViewModel:**

```typescript
// src/presentation/viewModels/LifeContext/useLifeContext.ts
export const useLifeContext = () => {
  const dispatch = useAppDispatch();
  const getLifeContextUseCase = container.resolve(GetLifeContextUseCase);

  const loadLifeContexts = useCallback(async () => {
    await dispatch(getLifeContextUseCase.execute()).unwrap();
  }, [dispatch, getLifeContextUseCase]);

  return { loadLifeContexts /* ... */ };
};
```

⚠️ **Missing:**

- StateManager should be here, not in Application layer

---

## 3. Dependency Violations

### Violation 1: Application → Presentation (Type Import)

**Severity:** Medium  
**Occurrences:** 3 files

**Files Affected:**

- `src/application/services/CalendarEventService.ts`
- `src/application/useCases/insight/GetInsight.usecase.ts`

**Problem:**

```typescript
// Application layer importing from Presentation layer
import { MetricWithValue } from "@/presentation/components/MetricLog/TrackingUtils";
```

**Impact:**

- Breaks dependency inversion principle
- Application layer depends on UI layer
- Cannot test application logic without presentation

**Fix:**
Move `MetricWithValue` type to `src/application/types/metrics/`

---

### Violation 2: Infrastructure → Presentation (DI Container)

**Severity:** Medium  
**Occurrences:** 1 file

**File Affected:**

- `src/infrastructure/di/container.ts`

**Problem:**

```typescript
// Infrastructure importing from Screens
import { HormoneDataGeneratorFactory } from "@/screens/StatusTab/Today/Chart/...";
```

**Impact:**

- DI container (infrastructure) depends on screens (presentation)
- Screens should not contain business logic

**Fix:**
Move hormone generator classes to `src/application/services/`

---

### Violation 3: Use Cases → Redux (Framework Coupling)

**Severity:** HIGH  
**Occurrences:** 24 use case files

**Problem:**

```typescript
// Use case tightly coupled to Redux Toolkit
@injectable()
export class SaveMetricLogsUseCase {
  execute = createAsyncThunk<SuccessMessage, Params, { rejectValue: string }>(
    "metricLog/saveLogs",
    async ({ logDate, inserts, deletes }, { rejectWithValue }) => {
      // business logic here
    },
  );
}
```

**Impact:**

- Use cases cannot be tested without Redux
- Use cases cannot be reused in CLI tools, scripts, or workers
- Application layer depends on specific state management library
- Violates framework-agnostic principle of Clean Architecture

**This is the PRIMARY issue to address.**

---

## 4. DI Container Usage Analysis

### Current DI Statistics

- **77 instances** of `@injectable/@inject` across 42 files
- **51 files** using `container.resolve()`

### Where DI is Used

| Category           | Files | DI Justified?                         |
| ------------------ | ----- | ------------------------------------- |
| Repositories       | 12    | ✅ Yes - need to swap implementations |
| Use Cases          | 24    | ✅ Yes - inject repositories/services |
| Stateful Services  | 6     | ⚠️ Maybe - could be pure functions    |
| Stateless Services | 8     | ❌ No - should be plain functions     |

### DI Benefits Realized

✅ **Testing:**

```typescript
// Easy to mock dependencies
const mockRepository = jest.fn() as jest.Mocked<LifeContextRepository>;
container.registerInstance("LifeContextRepository", mockRepository);
const useCase = container.resolve(GetLifeContextUseCase);
```

✅ **Abstraction:**

- Firebase implementation can be swapped for Supabase
- Can create mock implementations for development

### DI Costs

❌ **Bundle Size:**

- `tsyringe`: ~7KB gzipped
- `reflect-metadata`: ~50KB gzipped
- **Total:** ~57KB

❌ **Complexity:**

- 200 lines in `container.ts`
- Team training required
- Boilerplate in every class

### Recommendation

**Keep DI for:**

- ✅ Repositories (clear value)
- ✅ Use Cases (orchestration)
- ✅ Stateful services with dependencies

**Remove DI from:**

- ❌ Pure utility functions (`DateRangeService`)
- ❌ Static services (`UserAuthService`)

**Net Assessment:** DI is providing value, but could be streamlined.

---

## 5. Redux Integration Problem

### Current Pattern (Problematic)

**Use Case with Embedded Thunk:**

```typescript
// src/application/useCases/lifeContext/GetLifeContext.useCase.ts
@injectable()
export class GetLifeContextUseCase {
  constructor(
    @inject("LifeContextRepository")
    private repository: LifeContextRepository,
  ) {}

  execute = createAsyncThunk<
    ResultType,
    void,
    { rejectValue: string; state: RootState }
  >("lifeContext/getLifeContext", async (_, { getState, rejectWithValue }) => {
    const state = getState();
    const uid = UserAuthService.getAuthenticatedUid(state);

    try {
      const contexts = await this.repository.getAll(uid);
      // ... business logic
      return { contexts, activePregnancy, activeMenstruation };
    } catch (error) {
      return rejectWithValue(error.message);
    }
  });
}
```

**How Slices Consume:**

```typescript
// src/application/StateManager/slices/lifeContext/lifeContextSlice.ts
const lifeContextSlice = createSlice({
  name: "lifeContext",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    const getLifeContextThunk = container.resolve(
      GetLifeContextUseCase,
    ).execute;

    builder.addCase(getLifeContextThunk.pending, (state) => {
      state.loading = true;
    });
    builder.addCase(getLifeContextThunk.fulfilled, (state, action) => {
      state.contexts = action.payload.contexts;
    });
  },
});
```

### Problems with Current Pattern

❌ **1. Framework Lock-in**

- Use cases can ONLY be used with Redux
- Cannot call from:
  - CLI scripts
  - Background workers
  - Server-side rendering
  - Other state management libraries

❌ **2. Testing Complexity**

- Must mock Redux store
- Must mock `getState()`, `rejectWithValue()`
- Cannot test business logic in isolation

❌ **3. Mixed Responsibilities**

- Use case contains both:
  - Business logic (repository calls, data transformation)
  - State management logic (Redux thunk wrapper)

❌ **4. Architectural Violation**

- Application layer depends on Presentation framework
- Violates Clean Architecture's framework-agnostic principle

### Impact on All 24 Use Cases

**All affected use cases:**

1. GetLifeContextUseCase
2. InitiateMenstruationLifeContextUseCase
3. RestartMenstruationLifeContextUseCase
4. CalculateMenstrualCyclesUseCase
5. UpdateMenstrualPhaseLengthsDataUseCase
6. RecomputeAfterLifeContextChangeUseCase
7. SaveMenstruationOnboardingDataUseCase
8. SaveMetricLogsUseCase
9. ListMetricLogsUseCase
10. ListMetricCategoriesUseCase
11. ListBleedingLogsUseCase
12. GetStatusModeUseCase
13. ShouldShowCycleTrackingPromptUseCase
14. ClosePostPartumsUseCase
15. SetSicknessAndAilmentsUseCase
16. SetSexualActivityUseCase
17. SetPhysicalActivityUseCase
18. SetDrugUseUseCase
19. SetBirthControlUseCase
20. SetActivityFrequencyUseCase
21. GetInsightUseCase
22. GetCarefeedItemsUseCase
23. GetCarefeedFiltersUseCase
24. SetUserInterestsUseCase

**All 24 need refactoring.**

---

## 6. Recommended Architecture

### 6.1 Proposed Layer Structure

```
src/
├── container.ts               # DI container (bootstrap, outside layers)
├── old/                       # Legacy code being phased out
│
├── domain/                    # Core business rules (NO CHANGES)
│   ├── entities/
│   ├── repositories/          # Interfaces only
│   └── types/
│
├── application/               # Application orchestration (DECOUPLE FROM REDUX)
│   ├── useCases/              # ← Pure business logic (return Promise)
│   ├── services/              # ← Application services
│   ├── repositories/          # ← Repository interfaces
│   └── types/                 # ← Shared types (move MetricWithValue here)
│
├── infrastructure/            # External integrations (MINOR FIXES)
│   ├── firebase/              # Firebase implementations
│   └── sanity/                # Sanity implementations
│
└── presentation/              # UI and state management (ADD STATE)
    ├── state/                 # ← MOVE StateManager here
    │   ├── slices/            # Redux slices + thunks
    │   ├── listeners/         # Redux listeners
    │   └── store.ts           # Store configuration
    ├── viewModels/            # React hooks
    ├── components/            # UI components
    └── screens/               # Screens (legacy)
```

**DI Container Location:** `src/container.ts` sits outside the 4-layer structure because it's a "bootstrap" concern that wires together all layers. It's not business logic (Application), not external services (Infrastructure), not UI (Presentation), and not domain rules (Domain). It's infrastructure for the infrastructure.

### 6.2 Decoupled Use Case Pattern

**New Pattern - Use Case (Framework-Agnostic):**

```typescript
// src/application/useCases/lifeContext/GetLifeContext.useCase.ts
export interface GetLifeContextResult {
  contexts: LifeContext[];
  contextSequence: LifeContextSequenceElement[];
  activePregnancy: LifeContextId | undefined;
  activeMenstruation: LifeContextId | undefined;
}

@injectable()
export class GetLifeContextUseCase {
  constructor(
    @inject("LifeContextRepository")
    private repository: LifeContextRepository,
    @inject("LifeContextSequenceService")
    private sequenceService: LifeContextSequenceService,
  ) {}

  async execute(uid: string): Promise<GetLifeContextResult> {
    const contexts = await this.repository.getAll(uid);

    const activePregnancy = contexts.find(
      (c) =>
        isPregnancy(c.context) &&
        c.context.isActive &&
        !c.context.metadata.abortion,
    )?.context as Pregnancy | undefined;

    const activeMenstruation = contexts.find(
      (c) => isMenstruation(c.context) && c.context.isActive,
    )?.context as Menstruation | undefined;

    const contextSequence = this.sequenceService.createSequence(contexts);

    return {
      contexts,
      contextSequence,
      activePregnancy: activePregnancy?.id,
      activeMenstruation: activeMenstruation?.id,
    };
  }
}
```

**Redux Integration (Presentation Layer):**

```typescript
// src/presentation/state/slices/lifeContext/lifeContext.thunks.ts
import { createAsyncThunk } from "@reduxjs/toolkit";
import { container } from "tsyringe";
import { GetLifeContextUseCase } from "@/application/useCases/lifeContext/GetLifeContext.useCase";
import { RootState } from "../../store";
import { UserAuthService } from "@/application/services/UserAuthService";

export const fetchLifeContext = createAsyncThunk<
  GetLifeContextResult,
  void,
  { rejectValue: string; state: RootState }
>("lifeContext/fetch", async (_, { getState, rejectWithValue }) => {
  try {
    const state = getState();
    const uid = UserAuthService.getAuthenticatedUid(state);

    const useCase = container.resolve(GetLifeContextUseCase);
    return await useCase.execute(uid);
  } catch (error) {
    return rejectWithValue(
      error instanceof Error ? error.message : "Failed to fetch life contexts",
    );
  }
});
```

**Redux Slice:**

```typescript
// src/presentation/state/slices/lifeContext/lifeContext.slice.ts
import { createSlice } from "@reduxjs/toolkit";
import { fetchLifeContext } from "./lifeContext.thunks";

const lifeContextSlice = createSlice({
  name: "lifeContext",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchLifeContext.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchLifeContext.fulfilled, (state, action) => {
        state.loading = false;
        state.contexts = action.payload.contexts.reduce(
          (acc, context) => {
            acc[context.context.id] = context;
            return acc;
          },
          {} as { [id: string]: LifeContext },
        );
        state.contextSequence = action.payload.contextSequence;
        state.currentPregnancy = action.payload.activePregnancy ?? null;
        state.currentMenstruation = action.payload.activeMenstruation ?? null;
      })
      .addCase(fetchLifeContext.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to fetch life contexts";
      });
  },
});

export default lifeContextSlice.reducer;
```

### 6.3 Benefits of Decoupled Pattern

✅ **Framework-Agnostic Use Cases**

```typescript
// Can call from anywhere - no Redux needed!
const useCase = container.resolve(GetLifeContextUseCase);
const result = await useCase.execute(uid);
```

✅ **Easier Testing**

```typescript
// No Redux mocking required
const mockRepo = createMockRepository();
const useCase = new GetLifeContextUseCase(mockRepo, mockService);
const result = await useCase.execute("test-uid");
expect(result.contexts).toHaveLength(2);
```

✅ **Better Separation of Concerns**

- Use Case: Business logic only
- Thunk: Redux integration only
- Slice: State updates only

✅ **Reusability**

- Use cases can be called from:
  - React components (via Redux)
  - Node.js scripts
  - CLI tools
  - Background workers
  - Other state management (Zustand, MobX)

---

## 7. Migration Strategy

### Phase 1: Quick Wins (Week 1) 🎯

**Priority: HIGH | Effort: LOW**

#### 1.1 Fix Type Import Violations

**Task:** Move `MetricWithValue` to Application layer

```bash
# From:
src/presentation/components/MetricLog/TrackingUtils.ts

# To:
src/application/types/metrics/MetricWithValue.ts
```

**Files to Update:** 3 files

- `application/services/CalendarEventService.ts`
- `application/useCases/insight/GetInsight.usecase.ts`
- `presentation/components/MetricLog/TrackingUtils.ts`

**Estimated Time:** 30 minutes

---

#### 1.2 Move StateManager to Presentation

**Task:** Relocate Redux state management

```bash
# From:
src/application/StateManager/

# To:
src/presentation/state/
```

**Structure:**

```
src/presentation/state/
├── slices/
│   ├── lifeContext/
│   ├── metricLog/
│   ├── insight/
│   └── user/
├── listeners/
└── store.ts
```

**Files to Move:** 19 files (13 slices + 4 listeners + 2 config)

**Update Imports:** ~50 files reference `@/application/StateManager`

**Estimated Time:** 2-3 hours

---

### Phase 2: Decouple Use Cases (Weeks 2-3) 🎯

**Priority: HIGH | Effort: MEDIUM**

#### 2.1 Create Thunk Files

**For each of 24 use cases, create corresponding thunk file:**

```
src/presentation/state/thunks/
├── lifeContext.thunks.ts        # GetLifeContext, Initiate, Restart, etc.
├── metricLog.thunks.ts          # SaveLogs, ListLogs, etc.
├── myHealth.thunks.ts           # SetBirthControl, SetDrugUse, etc.
├── carefeed.thunks.ts           # GetCarefeedItems, GetFilters
├── insight.thunks.ts            # GetInsight
└── onboarding.thunks.ts         # SaveOnboardingData
```

**Pattern for Each Thunk:**

```typescript
// presentation/state/thunks/lifeContext.thunks.ts
export const fetchLifeContext = createAsyncThunk(
  "lifeContext/fetch",
  async (_, { getState, rejectWithValue }) => {
    try {
      const uid = selectAuthenticatedUid(getState());
      const useCase = container.resolve(GetLifeContextUseCase);
      return await useCase.execute(uid);
    } catch (error) {
      return rejectWithValue(error.message);
    }
  },
);
```

**Estimated Time:** 6-8 hours (24 thunks × 15-20 min each)

---

#### 2.2 Refactor Use Cases

**For each use case:**

1. Remove `createAsyncThunk` import
2. Change `execute` from thunk to async method
3. Remove Redux-specific parameters (`getState`, `rejectWithValue`)
4. Add required parameters to method signature
5. Return plain result type (not Redux action)

**Example Refactor:**

**BEFORE:**

```typescript
@injectable()
export class SaveMetricLogsUseCase {
  execute = createAsyncThunk<SuccessMessage, Params, { rejectValue: string }>(
    "metricLog/saveLogs",
    async ({ logDate, inserts, deletes }, { rejectWithValue }) => {
      try {
        return await this.repository.saveMetricLogs(logDate, inserts, deletes);
      } catch (error) {
        return rejectWithValue(error.message);
      }
    },
  );
}
```

**AFTER:**

```typescript
export interface SaveMetricLogsParams {
  logDate: Date;
  inserts: { metric_id: MetricId; value: number | null }[];
  deletes: MetricId[];
}

@injectable()
export class SaveMetricLogsUseCase {
  constructor(
    @inject("MetricLogRepository")
    private repository: MetricLogRepository,
  ) {}

  async execute(params: SaveMetricLogsParams): Promise<SuccessMessage> {
    const { logDate, inserts, deletes } = params;
    return await this.repository.saveMetricLogs(logDate, inserts, deletes);
  }
}
```

**Estimated Time:** 8-12 hours (24 use cases × 20-30 min each)

---

#### 2.3 Update Redux Slices

**For each slice:**

1. Remove `container.resolve()` from `extraReducers`
2. Import thunks from new thunk files
3. Update case handlers to use new thunk names
4. Keep reducer logic unchanged

**BEFORE:**

```typescript
extraReducers: (builder) => {
  const getLifeContextThunk = container.resolve(GetLifeContextUseCase).execute;
  builder.addCase(getLifeContextThunk.pending, (state) => {
    /*...*/
  });
};
```

**AFTER:**

```typescript
import { fetchLifeContext } from "../../thunks/lifeContext.thunks";

extraReducers: (builder) => {
  builder
    .addCase(fetchLifeContext.pending, (state) => {
      /*...*/
    })
    .addCase(fetchLifeContext.fulfilled, (state, action) => {
      /*...*/
    });
};
```

**Estimated Time:** 3-4 hours (13 slices × 15-20 min each)

---

#### 2.4 Update ViewModels

**For each ViewModel:**

1. Update dispatch calls to use new thunk names
2. Update imports

**BEFORE:**

```typescript
const getLifeContextUseCase = container.resolve(GetLifeContextUseCase);
await dispatch(getLifeContextUseCase.execute()).unwrap();
```

**AFTER:**

```typescript
import { fetchLifeContext } from "@/presentation/state/thunks/lifeContext.thunks";
await dispatch(fetchLifeContext()).unwrap();
```

**Estimated Time:** 2-3 hours (~20 ViewModels × 5-10 min each)

---

### Phase 3: Optimization (Week 4) 🎯

**Priority: MEDIUM | Effort: LOW**

#### 3.1 Simplify Stateless Services

**Convert DI services to plain functions:**

**BEFORE:**

```typescript
@injectable()
export class DateRangeService {
  createDateRange(startDate: Date, endDate: Date): DateRange {
    return new DateRange(startDate, endDate);
  }
}
```

**AFTER:**

```typescript
export const createDateRange = (startDate: Date, endDate: Date): DateRange => {
  return new DateRange(startDate, endDate);
};

export const createDateRangeFromContextSequence = (
  contextSequence: LifeContextSequenceElement[],
): DateRange => {
  // ... implementation
};
```

**Services to Convert:**

- `DateRangeService` → functions
- `UserAuthService` → functions (already static methods)

**Estimated Time:** 2 hours

---

#### 3.2 Fix Infrastructure Violations

**Move hormone generators from screens to application:**

```bash
# From:
src/screens/StatusTab/Today/Chart/Hormone/hormoneDataGenerator/

# To:
src/application/services/hormoneDataGenerator/
```

**Update DI Container:**

```typescript
// src/container.ts (moved outside layer structure)
import { HormoneDataGeneratorFactory } from "@/application/services/hormoneDataGenerator/...";
```

**Estimated Time:** 1 hour

---

#### 3.3 Add Architecture Tests

**Create automated boundary enforcement:**

```typescript
// __tests__/architecture.test.ts
import { checkDependencyRules } from "dependency-cruiser";

describe("Architecture Boundaries", () => {
  it("domain should not import from any other layer", () => {
    const result = checkDependencyRules("src/domain", {
      forbidden: ["src/application", "src/infrastructure", "src/presentation"],
    });
    expect(result.violations).toEqual([]);
  });

  it("application should not import from presentation", () => {
    const result = checkDependencyRules("src/application", {
      forbidden: ["src/presentation"],
    });
    expect(result.violations).toEqual([]);
  });

  it("application should not import from infrastructure", () => {
    const result = checkDependencyRules("src/application", {
      forbidden: ["src/infrastructure"],
    });
    expect(result.violations).toEqual([]);
  });
});
```

**Install dependency-cruiser:**

```bash
npm install --save-dev dependency-cruiser
```

**Estimated Time:** 2 hours

---

### Migration Timeline Summary

| Phase       | Tasks                             | Estimated Time  | Priority |
| ----------- | --------------------------------- | --------------- | -------- |
| **Phase 1** | Fix imports, Move StateManager    | 3-4 hours       | HIGH     |
| **Phase 2** | Decouple use cases, Create thunks | 19-27 hours     | HIGH     |
| **Phase 3** | Optimize services, Add tests      | 5 hours         | MEDIUM   |
| **TOTAL**   |                                   | **27-36 hours** |          |

**Recommended Sprint Allocation:**

- Sprint 1: Phase 1 (1 day)
- Sprint 2-3: Phase 2 (3-4 days)
- Sprint 4: Phase 3 (1 day)

---

## 8. Code Examples

### 8.1 Before/After: Use Case Decoupling

#### Example 1: GetLifeContextUseCase

**BEFORE (Coupled to Redux):**

```typescript
// src/application/useCases/lifeContext/GetLifeContext.useCase.ts
import { injectable, inject } from "tsyringe";
import { createAsyncThunk } from "@reduxjs/toolkit";
import { RootState } from "../../StateManager/store";

@injectable()
export class GetLifeContextUseCase {
  constructor(
    @inject("LifeContextRepository")
    private repository: LifeContextRepository,
    @inject("LifeContextSequenceService")
    private sequenceService: LifeContextSequenceService,
  ) {}

  execute = createAsyncThunk<
    {
      contexts: LifeContext[];
      contextSequence: LifeContextSequenceElement[];
      activePregnancy: LifeContextId | undefined;
      activeMenstruation: LifeContextId | undefined;
    },
    void,
    { rejectValue: string; state: RootState }
  >("lifeContext/getLifeContext", async (_, { getState, rejectWithValue }) => {
    const state = getState();
    const uid = UserAuthService.getAuthenticatedUid(state);

    try {
      const contexts = await this.repository.getAll(uid);
      const activePregnancy = contexts.find(/*...*/);
      const activeMenstruation = contexts.find(/*...*/);
      const contextSequence = this.sequenceService.createSequence(contexts);

      return {
        contexts,
        contextSequence,
        activePregnancy: activePregnancy?.id,
        activeMenstruation: activeMenstruation?.id,
      };
    } catch (error) {
      return rejectWithValue(error.message);
    }
  });
}
```

**AFTER (Framework-Agnostic):**

```typescript
// src/application/useCases/lifeContext/GetLifeContext.useCase.ts
import { injectable, inject } from "tsyringe";

export interface GetLifeContextResult {
  contexts: LifeContext[];
  contextSequence: LifeContextSequenceElement[];
  activePregnancy: LifeContextId | undefined;
  activeMenstruation: LifeContextId | undefined;
}

@injectable()
export class GetLifeContextUseCase {
  constructor(
    @inject("LifeContextRepository")
    private repository: LifeContextRepository,
    @inject("LifeContextSequenceService")
    private sequenceService: LifeContextSequenceService,
  ) {}

  async execute(uid: string): Promise<GetLifeContextResult> {
    const contexts = await this.repository.getAll(uid);

    const activePregnancy = contexts.find(
      (c) =>
        isPregnancy(c.context) &&
        c.context.isActive &&
        !c.context.metadata.abortion,
    )?.context as Pregnancy | undefined;

    const activeMenstruation = contexts.find(
      (c) => isMenstruation(c.context) && c.context.isActive,
    )?.context as Menstruation | undefined;

    const contextSequence = this.sequenceService.createSequence(contexts);

    return {
      contexts,
      contextSequence,
      activePregnancy: activePregnancy?.id,
      activeMenstruation: activeMenstruation?.id,
    };
  }
}
```

**NEW: Redux Thunk (Presentation Layer):**

```typescript
// src/presentation/state/thunks/lifeContext.thunks.ts
import { createAsyncThunk } from "@reduxjs/toolkit";
import { container } from "tsyringe";
import { GetLifeContextUseCase } from "@/application/useCases/lifeContext/GetLifeContext.useCase";
import type { GetLifeContextResult } from "@/application/useCases/lifeContext/GetLifeContext.useCase";
import { RootState } from "../store";

export const fetchLifeContext = createAsyncThunk<
  GetLifeContextResult,
  void,
  { rejectValue: string; state: RootState }
>("lifeContext/fetch", async (_, { getState, rejectWithValue }) => {
  try {
    const state = getState();
    const uid = (state.user as any).uid;

    if (!uid) {
      return rejectWithValue("User not authenticated");
    }

    const useCase = container.resolve(GetLifeContextUseCase);
    return await useCase.execute(uid);
  } catch (error) {
    return rejectWithValue(
      error instanceof Error ? error.message : "Failed to fetch life contexts",
    );
  }
});
```

**NEW: Redux Slice (Updated):**

```typescript
// src/presentation/state/slices/lifeContext/lifeContext.slice.ts
import { createSlice } from "@reduxjs/toolkit";
import { fetchLifeContext } from "../../thunks/lifeContext.thunks";

const lifeContextSlice = createSlice({
  name: "lifeContext",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchLifeContext.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchLifeContext.fulfilled, (state, action) => {
        state.loading = false;
        state.contexts = action.payload.contexts.reduce(
          (acc, context) => {
            acc[context.context.id] = context;
            return acc;
          },
          {} as { [id: string]: LifeContext },
        );
        state.contextSequence = action.payload.contextSequence;
        state.currentPregnancy = action.payload.activePregnancy ?? null;
        state.currentMenstruation = action.payload.activeMenstruation ?? null;
      })
      .addCase(fetchLifeContext.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to fetch life contexts";
      });
  },
});

export default lifeContextSlice.reducer;
```

---

#### Example 2: SaveMetricLogsUseCase

**BEFORE:**

```typescript
// src/application/useCases/metricLog/SaveMetricLogs.useCase.ts
import { injectable, inject } from "tsyringe";
import { createAsyncThunk } from "@reduxjs/toolkit";

@injectable()
export class SaveMetricLogsUseCase {
  constructor(
    @inject("MetricLogRepository")
    private repository: MetricLogRepository,
  ) {}

  execute = createAsyncThunk<
    SuccessMessage,
    { logDate: Date; inserts: Insert[]; deletes: MetricId[] },
    { rejectValue: string }
  >(
    "metricLog/saveLogs",
    async ({ logDate, inserts, deletes }, { rejectWithValue }) => {
      try {
        return await this.repository.saveMetricLogs(logDate, inserts, deletes);
      } catch (error) {
        return rejectWithValue(error.message);
      }
    },
  );
}
```

**AFTER:**

```typescript
// src/application/useCases/metricLog/SaveMetricLogs.useCase.ts
import { injectable, inject } from "tsyringe";

export interface SaveMetricLogsParams {
  logDate: Date;
  inserts: { metric_id: MetricId; value: number | null }[];
  deletes: MetricId[];
}

@injectable()
export class SaveMetricLogsUseCase {
  constructor(
    @inject("MetricLogRepository")
    private repository: MetricLogRepository,
  ) {}

  async execute(params: SaveMetricLogsParams): Promise<SuccessMessage> {
    const { logDate, inserts, deletes } = params;
    return await this.repository.saveMetricLogs(logDate, inserts, deletes);
  }
}
```

**NEW: Thunk:**

```typescript
// src/presentation/state/thunks/metricLog.thunks.ts
import { createAsyncThunk } from "@reduxjs/toolkit";
import { container } from "tsyringe";
import { SaveMetricLogsUseCase } from "@/application/useCases/metricLog/SaveMetricLogs.useCase";
import type { SaveMetricLogsParams } from "@/application/useCases/metricLog/SaveMetricLogs.useCase";

export const saveMetricLogs = createAsyncThunk<
  SuccessMessage,
  SaveMetricLogsParams,
  { rejectValue: string }
>("metricLog/save", async (params, { rejectWithValue }) => {
  try {
    const useCase = container.resolve(SaveMetricLogsUseCase);
    return await useCase.execute(params);
  } catch (error) {
    return rejectWithValue(
      error instanceof Error ? error.message : "Failed to save metric logs",
    );
  }
});
```

---

### 8.2 Testing Improvements

#### Before (Requires Redux Mocking)

```typescript
// BEFORE: Hard to test
describe("GetLifeContextUseCase", () => {
  it("should fetch contexts", async () => {
    // Must mock Redux store, dispatch, getState, etc.
    const mockDispatch = jest.fn();
    const mockGetState = jest.fn(() => ({ user: { uid: "test-uid" } }));

    const thunk = useCase.execute();
    await thunk(mockDispatch, mockGetState, undefined);

    expect(mockDispatch).toHaveBeenCalled();
    // Complex assertions...
  });
});
```

#### After (Pure Function Testing)

```typescript
// AFTER: Clean, simple tests
describe("GetLifeContextUseCase", () => {
  let useCase: GetLifeContextUseCase;
  let mockRepository: jest.Mocked<LifeContextRepository>;
  let mockSequenceService: jest.Mocked<LifeContextSequenceService>;

  beforeEach(() => {
    mockRepository = {
      getAll: jest.fn(),
    } as any;

    mockSequenceService = {
      createSequence: jest.fn(),
    } as any;

    useCase = new GetLifeContextUseCase(mockRepository, mockSequenceService);
  });

  it("should fetch and return life contexts", async () => {
    // Arrange
    const mockContexts = [mockPregnancy, mockMenstruation];
    mockRepository.getAll.mockResolvedValue(mockContexts);
    mockSequenceService.createSequence.mockReturnValue(mockSequence);

    // Act
    const result = await useCase.execute("test-uid");

    // Assert
    expect(result.contexts).toEqual(mockContexts);
    expect(result.activePregnancy).toBe(mockPregnancy.id);
    expect(mockRepository.getAll).toHaveBeenCalledWith("test-uid");
  });

  it("should handle errors gracefully", async () => {
    // Arrange
    mockRepository.getAll.mockRejectedValue(new Error("Network error"));

    // Act & Assert
    await expect(useCase.execute("test-uid")).rejects.toThrow("Network error");
  });
});
```

---

### 8.3 Reusability Examples

With decoupled use cases, you can now:

#### CLI Script

```typescript
// scripts/export-life-contexts.ts
import { container } from "tsyringe";
import { GetLifeContextUseCase } from "@/application/useCases/lifeContext/GetLifeContext.useCase";

async function exportLifeContexts(uid: string) {
  const useCase = container.resolve(GetLifeContextUseCase);
  const result = await useCase.execute(uid);

  console.log(`Exporting ${result.contexts.length} contexts...`);
  // Write to file, send to API, etc.
}

exportLifeContexts(process.argv[2]);
```

#### Background Worker

```typescript
// workers/sync-contexts.worker.ts
import { container } from "tsyringe";
import { GetLifeContextUseCase } from "@/application/useCases/lifeContext/GetLifeContext.useCase";

self.addEventListener("message", async (event) => {
  const { uid } = event.data;

  const useCase = container.resolve(GetLifeContextUseCase);
  const result = await useCase.execute(uid);

  // Sync to external service
  self.postMessage({ success: true, count: result.contexts.length });
});
```

#### Different State Management (Zustand)

```typescript
// store/lifeContextStore.ts (Zustand example)
import create from "zustand";
import { container } from "tsyringe";
import { GetLifeContextUseCase } from "@/application/useCases/lifeContext/GetLifeContext.useCase";

export const useLifeContextStore = create((set) => ({
  contexts: [],
  loading: false,

  fetchContexts: async (uid: string) => {
    set({ loading: true });

    const useCase = container.resolve(GetLifeContextUseCase);
    const result = await useCase.execute(uid);

    set({ contexts: result.contexts, loading: false });
  },
}));
```

---

## 9. Decision Framework

### When to Use Each Pattern

#### Use DI + Use Cases When

✅ Complex business logic with multiple dependencies  
✅ Need to swap implementations (repositories)  
✅ Need testability with mocks  
✅ Logic will be reused across different contexts

**Example:** `GetLifeContextUseCase` - orchestrates multiple services, needs testing

---

#### Use Plain Functions When

✅ Stateless transformations  
✅ No dependencies  
✅ Pure functions  
✅ Simple utilities

**Example:** Date formatting, validation helpers

---

#### Use Thunks (Presentation) When

✅ Connecting use cases to Redux  
✅ Accessing Redux state  
✅ Dispatching multiple actions  
✅ UI-specific orchestration

**Example:** Fetching data and updating loading states

---

#### Keep in Application Layer

- ✅ Use cases (business workflows)
- ✅ Application services (orchestration logic)
- ✅ Repository interfaces
- ✅ Domain-specific types
- ❌ NOT Redux, NOT React hooks, NOT UI components

---

#### Keep in Presentation Layer

- ✅ Redux (store, slices, thunks, listeners)
- ✅ React hooks (ViewModels)
- ✅ UI components
- ✅ Screen-specific logic
- ❌ NOT business rules, NOT data access

---

### Architecture Checklist

Use this checklist when adding new features:

**For New Business Logic:**

- [ ] Is this a business rule? → Add to Domain
- [ ] Does it orchestrate multiple operations? → Create Use Case
- [ ] Does it need external data? → Define Repository interface

**For New UI Features:**

- [ ] Does it manage state? → Create Redux slice
- [ ] Does it call use cases? → Create thunk
- [ ] Does it format data for display? → Create ViewModel hook
- [ ] Is it visual? → Create Component

**For New External Services:**

- [ ] Implement Repository interface in Infrastructure
- [ ] Register in DI container
- [ ] Add serializers/mappers as needed

---

## 10. Conclusion

### Summary of Recommendations

| Recommendation                        | Priority | Effort | Impact                  |
| ------------------------------------- | -------- | ------ | ----------------------- |
| **Keep 4-layer architecture**         | N/A      | None   | Maintains clarity       |
| **Decouple use cases from Redux**     | HIGH     | Medium | Framework independence  |
| **Move StateManager to Presentation** | HIGH     | Low    | Correct layer placement |
| **Fix cross-layer type imports**      | HIGH     | Low    | Clean dependencies      |
| **Create thunk files**                | HIGH     | Medium | Separation of concerns  |
| **Simplify stateless services**       | MEDIUM   | Low    | Reduced complexity      |
| **Add architecture tests**            | MEDIUM   | Low    | Prevent regressions     |

### Key Principles Moving Forward

1. **Application Layer = Framework-Agnostic**

   - No Redux imports
   - No React imports
   - Pure TypeScript business logic

2. **Presentation Layer = UI & State**

   - Redux thunks live here
   - React hooks live here
   - ViewModels live here

3. **Infrastructure Layer = External World**

   - Database implementations
   - API clients
   - Third-party services

4. **Domain Layer = Pure Business Rules**
   - Zero dependencies
   - Framework-agnostic
   - Highly testable

### Expected Outcomes

After migration:

✅ **Use cases are testable** without Redux  
✅ **Use cases are reusable** in scripts, workers, CLI  
✅ **Clear layer boundaries** with no violations  
✅ **Easier to swap** state management libraries  
✅ **Better team understanding** of architecture  
✅ **Faster development** with clear patterns

### Next Steps

1. **Review this report** with the team
2. **Approve migration plan** and timeline
3. **Start with Phase 1** (quick wins)
4. **Create tracking issues** for each phase
5. **Document patterns** as you go
6. **Update team guidelines** with new patterns

---

## Appendix A: Complete Use Case List

All 24 use cases requiring refactoring:

### LifeContext (7)

1. `GetLifeContextUseCase`
2. `InitiateMenstruationLifeContextUseCase`
3. `RestartMenstruationLifeContextUseCase`
4. `CalculateMenstrualCyclesUseCase`
5. `UpdateMenstrualPhaseLengthsDataUseCase`
6. `RecomputeAfterLifeContextChangeUseCase`
7. `GetStatusModeUseCase`

### MetricLog (4)

8. `SaveMetricLogsUseCase`
9. `ListMetricLogsUseCase`
10. `ListMetricCategoriesUseCase`
11. `ListBleedingLogsUseCase`

### MyHealth (5)

12. `SetSicknessAndAilmentsUseCase`
13. `SetSexualActivityUseCase`
14. `SetPhysicalActivityUseCase`
15. `SetDrugUseUseCase`
16. `SetBirthControlUseCase`

### Other (8)

17. `SetActivityFrequencyUseCase`
18. `ShouldShowCycleTrackingPromptUseCase`
19. `ClosePostPartumsUseCase`
20. `SaveMenstruationOnboardingDataUseCase`
21. `GetInsightUseCase`
22. `GetCarefeedItemsUseCase`
23. `GetCarefeedFiltersUseCase`
24. `SetUserInterestsUseCase`

---

## Appendix B: File Move Checklist

### StateManager Migration

**From `src/application/StateManager/` to `src/presentation/state/`:**

- [ ] `store.ts`
- [ ] `slices/lifeContext/lifeContextSlice.ts`
- [ ] `slices/lifeContext/statusModeSlice.ts`
- [ ] `slices/lifeContext/lifeContextTriggers.ts`
- [ ] `slices/metricLog/metricLogSlice.ts`
- [ ] `slices/insight/insightSlice.ts`
- [ ] `slices/user/health.slice.ts`
- [ ] `slices/onboarding/onboarding.slice.ts`
- [ ] `slices/sanity/carefeedQuerySlice.ts`
- [ ] `slices/app/appSlice.ts`
- [ ] `listeners/menstrualCycle.listeners.ts`
- [ ] `listeners/insight.listeners.ts`
- [ ] `listeners/recomputation.listeners.ts`
- [ ] `listeners/onboarding.listners.ts`

**Update imports in ~50 files** that reference `@/application/StateManager`

---

## Appendix C: Resources

### Recommended Reading

- **Clean Architecture** by Robert C. Martin - Chapters 17-22
- **The Pragmatic Programmer** (2nd Ed.) - Chapter on "Decoupling"
- [Redux Toolkit Best Practices](https://redux-toolkit.js.org/usage/usage-guide)
- [Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)

### Tools

- **dependency-cruiser** - Enforce architecture boundaries
- **ts-morph** - Automated refactoring scripts
- **madge** - Visualize dependency graphs

### Team Training

Consider scheduling:

- 1-hour workshop on "Clean Architecture Principles"
- 30-min demo of "Decoupled Use Case Pattern"
- Code review session for first refactored use case

---

**Report End**

_For questions or clarifications, please contact the architecture team._
