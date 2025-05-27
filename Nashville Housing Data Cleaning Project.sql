
/*

Cleaning Nashville Housing Data in SQL Queries

*/


Select*
From [Portfolio Project]..[Nashville Housing]



--Standardizing Date Format
ALTER TABLE [Portfolio Project]..[Nashville Housing]
ALTER COLUMN Saledate DATE;



--Populating Property Address Data
Select *
From [Portfolio Project]..[Nashville Housing]
--Where PropertyAddress is NULL
order by ParcelID

----Using Join Clause and ISNULL Function to populate the Property Address 
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From [Portfolio Project]..[Nashville Housing] a
JOIN [Portfolio Project]..[Nashville Housing] b
on a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is NULL

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From [Portfolio Project]..[Nashville Housing] a
JOIN [Portfolio Project]..[Nashville Housing] b
on a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is NULL




--Breaking out Address into Individual Columns (Address, City, State)
Select PropertyAddress
From [Portfolio Project]..[Nashville Housing]


----SUBSTRING and CHARINDEX to break the Property Address into Individual columns
Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
From [Portfolio Project]..[Nashville Housing]

----Creating Columns to add the above split results
ALTER TABLE [Portfolio Project]..[Nashville Housing]
ADD PropertySplitAddress Nvarchar(255);

Update [Portfolio Project]..[Nashville Housing]
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE [Portfolio Project]..[Nashville Housing]
ADD PropertySplitCity Nvarchar(255);

Update [Portfolio Project]..[Nashville Housing]
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))




--Splitting Owner Address into individual Columns
Select OwnerAddress
From [Portfolio Project]..[Nashville Housing]

----Using PARSENAME to split Owner Address into Address, City and State
Select
PARSENAME (Replace(OwnerAddress, ',', '.'), 3),
PARSENAME (Replace(OwnerAddress, ',', '.'), 2),
PARSENAME (Replace(OwnerAddress, ',', '.'), 1)
From [Portfolio Project]..[Nashville Housing]

----Creating Columns to add the above split results
ALTER TABLE [Portfolio Project]..[Nashville Housing]
ADD OwnerSplitAddress Nvarchar(255);

Update [Portfolio Project]..[Nashville Housing]
SET OwnerSplitAddress = PARSENAME (Replace(OwnerAddress, ',', '.'), 3)

ALTER TABLE [Portfolio Project]..[Nashville Housing]
ADD OwnerSplitCity Nvarchar(255);

Update [Portfolio Project]..[Nashville Housing]
SET OwnerSplitCity = PARSENAME (Replace(OwnerAddress, ',', '.'), 2)

ALTER TABLE [Portfolio Project]..[Nashville Housing]
ADD OwnerSplitState Nvarchar(255);

Update [Portfolio Project]..[Nashville Housing]
SET OwnerSplitState = PARSENAME (Replace(OwnerAddress, ',', '.'), 1)




--Changing Y and N to Yes and No in "Sold as Vacant" field
Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From [Portfolio Project]..[Nashville Housing]
Group by SoldAsVacant
Order by 2


----Using Case Statement
Select SoldAsVacant,
Case When SoldAsVacant = 'Y' THEN 'Yes'
     When SoldAsVacant = 'N' THEN 'No'
	 Else SoldAsVacant
	 END
From [Portfolio Project]..[Nashville Housing]

Update [Portfolio Project]..[Nashville Housing]
SET SoldAsVacant = Case When SoldAsVacant = 'Y' THEN 'Yes'
     When SoldAsVacant = 'N' THEN 'No'
	 Else SoldAsVacant
	 END




--Removing Duplicates
----Using CTE and Row Number
WITH RowNumCTE AS(
Select*,
    ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
	             PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order By
				   UniqueID
				   ) row_num

From [Portfolio Project]..[Nashville Housing])

DELETE
From RowNumCTE
Where row_num > 1




--Deleting Unused Columns
Select *
From [Portfolio Project]..[Nashville Housing]

ALTER TABLE [Portfolio Project]..[Nashville Housing]
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict




